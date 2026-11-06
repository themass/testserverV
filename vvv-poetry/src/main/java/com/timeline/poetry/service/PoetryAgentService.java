package com.timeline.poetry.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.timeline.poetry.api.PoetryAgentModels.*;
import com.timeline.poetry.api.PoetryDraftModels.AnnotationWrite;
import com.timeline.poetry.api.PoetryDraftModels.DraftContent;
import com.timeline.poetry.persistence.PoetryAgentMapper;
import org.springframework.transaction.annotation.Transactional;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * The domain authority for Agent operations. It does not publish, verify sources, delete rows,
 * execute arbitrary SQL, or allow proposal text to become fact without an explicit DRAFT operation.
 */
public class PoetryAgentService {
    private static final Set<String> CHANGE_TYPES = Set.of("GAP_REPORT", "ANNOTATION", "BACKGROUND", "CLAIM", "SCRIPT");
    private final PoetryAgentMapper mapper;
    private final PoetryTextService texts;
    private final AuditRunner audit;
    private final ObjectMapper json;

    public PoetryAgentService(PoetryAgentMapper mapper, PoetryTextService texts, AuditRunner audit, ObjectMapper json) {
        this.mapper = mapper; this.texts = texts; this.audit = audit; this.json = json;
    }

    public Snapshot snapshot(String workId) {
        DraftContent work = requireWork(workId);
        return new Snapshot(work, mapper.workInfo(workId), mapper.versions(workId), mapper.lines(workId),
            mapper.claims(workId), mapper.citations(workId), mapper.backgrounds(workId),
            mapper.annotations(workId), mapper.sources(workId));
    }

    public GapReport gaps(String workId) {
        requireWork(workId);
        List<Gap> gaps = new ArrayList<>();
        if (zero(mapper.versions(workId).size())) gaps.add(gap("TEXT_VERSION_MISSING", "HIGH", "作品尚无文本定本草稿。", workId));
        if (zero(mapper.lineCount(workId))) gaps.add(gap("TEXT_LINES_MISSING", "HIGH", "文本定本没有逐句行，不能形成可核验阅读路径。", workId));
        int unverified = n(mapper.unverifiedClaimCount(workId));
        if (unverified > 0) gaps.add(gap("CLAIM_VERIFIED_CITATION_MISSING", "HIGH", "有 " + unverified + " 条 Claim 缺少已核验且带 locator 的出处。", workId));
        int pendingSources = n(mapper.pendingTextSourceCount(workId));
        if (pendingSources > 0) gaps.add(gap("TEXT_SOURCE_NOT_VERIFIED", "HIGH", "有 " + pendingSources + " 个文本定本来源仍非 VERIFIED；本报告不要求 Agent 验证来源。", workId));
        Set<String> layers = new java.util.HashSet<>();
        mapper.backgrounds(workId).forEach(x -> layers.add(x.layer()));
        for (String layer : List.of("SCENE", "CITY", "WORLD", "PERSON"))
            if (!layers.contains(layer)) gaps.add(gap("BACKGROUND_LAYER_MISSING", "MEDIUM", "缺少 " + layer + " 背景草稿。", workId));
        if (mapper.annotations(workId).size() < 4)
            gaps.add(gap("ANNOTATION_COVERAGE_LOW", "MEDIUM", "当前注释少于 4 条；数量不是发布条件，需由人工判断学习价值。", workId));
        AuditRunner.Result auditResult = audit.run();
        auditResult.nonZero().forEach(x -> gaps.add(gap("INTEGRITY_AUDIT_NONZERO", "HIGH", x, workId)));
        return new GapReport(workId, List.copyOf(gaps), auditResult.totalChecks(), auditResult.nonZero());
    }

    @Transactional
    public AgentResponse<Map<String, Object>> createProposal(Context c, ProposalCreate request) {
        requireWork(request.workId());
        validateProposal(request.proposal(), request.workId());
        String id = proposalId(request.proposalId());
        String existing = mapper.receipt("CREATE_PROPOSAL", c.idempotencyKey());
        if (existing != null) return AgentResponse.ok(Map.of("proposal_id", existing, "idempotent", true), List.of("agent-receipt:" + existing));
        mapper.ensureMandate(c.runId(), c.mandateId(), request.workId(), c.role());
        try {
            mapper.proposalInsert(id, request.workId(), c.runId(), c.mandateId(), json.writeValueAsString(request.proposal()));
            mapper.receiptInsert("CREATE_PROPOSAL", c.idempotencyKey(), c.runId(), c.mandateId(), id);
        } catch (Exception ex) {
            throw new Conflict("proposal or idempotency key already exists");
        }
        return AgentResponse.review(Map.of("proposal_id", id, "stored_status", "DRAFT", "review_status", "PENDING"), List.of("agent-proposal:" + id));
    }

    @Transactional
    public AgentResponse<Map<String, Object>> reviewProposal(Context c, String proposalId, ProposalReview request) {
        String workId = mapper.proposalWorkId(proposalId);
        if (workId == null) throw new Rejected("proposal not found");
        requireMandate(c, workId);
        if (!"APPROVE".equals(request.decision()) && !"REJECT".equals(request.decision())) throw new Rejected("decision must be APPROVE or REJECT");
        if (blank(request.reviewId()) || blank(request.reviewerId())) throw new Rejected("review_id and reviewer_id are required");
        String receipt = mapper.receipt("REVIEW_PROPOSAL", c.idempotencyKey());
        if (receipt != null) return AgentResponse.ok(Map.of("proposal_id", proposalId, "review_id", receipt, "idempotent", true), List.of("agent-review:" + receipt));
        int written = mapper.reviewProposal(proposalId, request.reviewId(), "APPROVE".equals(request.decision()) ? "APPROVED" : "REJECTED", request.reviewerId(), request.comment());
        if (written != 1) throw new Conflict("proposal is no longer pending review");
        mapper.reviewInsert(request.reviewId(), proposalId, request.reviewerId(), request.decision(), request.comment());
        mapper.receiptInsert("REVIEW_PROPOSAL", c.idempotencyKey(), c.runId(), c.mandateId(), request.reviewId());
        if ("REJECT".equals(request.decision())) return AgentResponse.ok(Map.of("proposal_id", proposalId, "review_status", "REJECTED"), List.of("agent-review:" + request.reviewId()));
        return AgentResponse.ok(Map.of("proposal_id", proposalId, "review_status", "APPROVED"), List.of("agent-review:" + request.reviewId()));
    }

    @Transactional
    public AgentResponse<Map<String, Object>> apply(Context c, String proposalId, ProposalApply request) {
        String workId = mapper.proposalWorkId(proposalId);
        if (workId == null) throw new Rejected("proposal not found");
        requireMandate(c, workId);
        if (!"APPROVED".equals(mapper.proposalReviewStatus(proposalId))) throw new Conflict("proposal needs an APPROVED human review");
        if (blank(request.reviewId())) throw new Rejected("review_id is required");
        String receipt = mapper.receipt("APPLY_PROPOSAL", c.idempotencyKey());
        if (receipt != null) return AgentResponse.ok(Map.of("proposal_id", proposalId, "application_id", receipt, "idempotent", true), List.of("agent-receipt:" + receipt));
        JsonNode proposal;
        try { proposal = json.readTree(mapper.proposalJson(proposalId)); }
        catch (Exception ex) { throw new Rejected("stored proposal JSON is unreadable"); }
        List<String> applied = new ArrayList<>();
        List<String> retained = new ArrayList<>();
        for (JsonNode change : proposal.path("changes")) {
            JsonNode payload = change.path("draft_payload");
            if (payload.isMissingNode() || payload.isNull()) { retained.add(change.path("change_type").asText()); continue; }
            String operation = payload.path("operation").asText();
            if (!"CREATE_ANNOTATION".equals(operation)) throw new Rejected("unsupported DRAFT operation: " + operation);
            AnnotationWrite annotation = new AnnotationWrite(
                text(payload, "id"), text(payload, "version_id"), integer(payload, "line_seq"), text(payload, "annotation_kind"),
                text(payload, "audience"), text(payload, "content"), text(payload, "claim_id"), text(payload, "claim_value"),
                text(payload, "certainty"), nullable(payload, "source_id"), nullable(payload, "locator"));
            texts.createAnnotation(annotation); // internally validates links and leaves DRAFT-only rows
            applied.add("CREATE_ANNOTATION:" + annotation.id());
        }
        if (mapper.markApplied(proposalId) != 1) throw new Conflict("proposal cannot transition to APPLIED");
        String applicationId = "application_" + UUID.randomUUID().toString().replace("-", "");
        mapper.receiptInsert("APPLY_PROPOSAL", c.idempotencyKey(), c.runId(), c.mandateId(), applicationId);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("proposal_id", proposalId); data.put("application_id", applicationId); data.put("content_state", "DRAFT_ONLY");
        data.put("applied_operations", applied); data.put("retained_editorial_changes", retained);
        return AgentResponse.ok(data, List.of("agent-application:" + applicationId, "agent-review:" + request.reviewId()));
    }

    @Transactional
    public AgentResponse<Map<String, Object>> requestCompile(Context c, String workId, CompileRequest request) {
        requireWork(workId); requireMandate(c, workId);
        if (blank(request.scriptVersion())) throw new Rejected("script_version is required");
        String receipt = mapper.receipt("REQUEST_COMPILE", c.idempotencyKey());
        if (receipt != null) return AgentResponse.review(Map.of("compile_request_id", receipt, "idempotent", true), List.of("compile-request:" + receipt));
        GapReport report = gaps(workId);
        String id = "compile_" + UUID.randomUUID().toString().replace("-", "");
        String state = report.gaps().isEmpty() ? "PENDING_REVIEW" : "BLOCKED";
        String reason = report.gaps().isEmpty() ? "Agent requested eligibility review; this is not compilation or publication." : "Gap report must be reviewed before compiler eligibility.";
        mapper.compileInsert(id, workId, request.scriptVersion(), c.runId(), c.mandateId(), state, reason);
        mapper.receiptInsert("REQUEST_COMPILE", c.idempotencyKey(), c.runId(), c.mandateId(), id);
        return AgentResponse.review(Map.of("compile_request_id", id, "state", state, "reason", reason), List.of("compile-request:" + id));
    }

    private void validateProposal(JsonNode proposal, String workId) {
        if (proposal == null || !proposal.isObject() || proposal.path("schema_version").asInt(-1) != 1 || !"DRAFT".equals(proposal.path("status").asText()))
            throw new Rejected("proposal must be a schema_version=1 DRAFT object");
        if (blank(proposal.path("summary").asText()) || blank(proposal.path("human_review_question").asText())) throw new Rejected("proposal summary and human_review_question are required");
        JsonNode changes = proposal.path("changes");
        if (!changes.isArray() || changes.isEmpty() || changes.size() > 50) throw new Rejected("proposal changes must contain 1..50 items");
        for (JsonNode change : changes) {
            if (!CHANGE_TYPES.contains(change.path("change_type").asText()) || blank(change.path("body").asText())) throw new Rejected("invalid proposal change");
            String classification = change.path("classification").asText();
            if (!("DRAFT".equals(classification) || "INTERPRETATION".equals(classification) || "UNKNOWN".equals(classification))) throw new Rejected("invalid change classification");
            JsonNode payload = change.path("draft_payload");
            if (!payload.isMissingNode() && !payload.isNull() && !"CREATE_ANNOTATION".equals(payload.path("operation").asText())) throw new Rejected("only CREATE_ANNOTATION is an executable v1 operation");
        }
        requireWork(workId);
    }

    private DraftContent requireWork(String workId) {
        if (blank(workId) || !workId.matches("[A-Za-z0-9][A-Za-z0-9_-]{1,127}")) throw new Rejected("invalid work id");
        DraftContent work = mapper.work(workId);
        if (work == null || !"WORK".equals(work.entityType())) throw new Rejected("work not found");
        return work;
    }
    private void requireMandate(Context c, String workId) {
        if (blank(c.runId()) || blank(c.mandateId()) || blank(c.idempotencyKey())) throw new Rejected("run, mandate and idempotency headers are required");
        if (n(mapper.activeMandate(c.runId(), c.mandateId(), workId)) != 1) throw new Rejected("active mandate not found for this work");
    }
    private static Gap gap(String code, String severity, String message, String target) { return new Gap(code, severity, message, target); }
    private static boolean zero(int value) { return value == 0; }
    private static int n(Integer value) { return value == null ? 0 : value; }
    private static boolean blank(String s) { return s == null || s.isBlank(); }
    private static String proposalId(String proposed) { return blank(proposed) ? "proposal_" + UUID.randomUUID().toString().replace("-", "") : proposed; }
    private static String text(JsonNode node, String key) { String value = nullable(node, key); if (blank(value)) throw new Rejected("draft_payload." + key + " is required"); return value; }
    private static String nullable(JsonNode node, String key) { JsonNode value = node.get(key); return value == null || value.isNull() ? null : value.asText(); }
    private static Integer integer(JsonNode node, String key) { if (!node.has(key) || !node.get(key).canConvertToInt()) throw new Rejected("draft_payload." + key + " must be an integer"); return node.get(key).asInt(); }

    public record Context(String runId, String mandateId, String idempotencyKey, String role) {}
    public static class Rejected extends RuntimeException { public Rejected(String message) { super(message); } }
    public static class Conflict extends RuntimeException { public Conflict(String message) { super(message); } }
}
