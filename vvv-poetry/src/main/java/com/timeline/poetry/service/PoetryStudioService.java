package com.timeline.poetry.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.timeline.poetry.api.PoetryAgentModels.Gap;
import com.timeline.poetry.api.PoetryAgentModels.GapReport;
import com.timeline.poetry.api.PoetryStudioModels.ItemDecision;
import com.timeline.poetry.api.PoetryStudioModels.ItemDecisions;
import com.timeline.poetry.api.PoetryStudioModels.LocatorUpdate;
import com.timeline.poetry.api.PoetryStudioModels.SourceVerification;
import com.timeline.poetry.domain.PoetryStudioRules;
import com.timeline.poetry.domain.PoetryStudioRules.LocatorState;
import com.timeline.poetry.persistence.PoetryStudioMapper;
import com.timeline.poetry.persistence.PoetryStudioMapper.LogEntry;
import org.springframework.transaction.annotation.Transactional;
import java.sql.Clob;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;

/**
 * Poetry Studio 治理：只读视图 + 三个"人工写入"。
 * 这里不创建内容、不发布 claim/版本；唯一能改来源状态的路径是复用 {@link PoetryReviewService}(含发布闸门与 106 项审计)。
 */
public class PoetryStudioService {
    public static final int DEFAULT_LIMIT = 50;
    public static final int MAX_LIMIT = 200;
    private static final int MAX_ITEMS = 50;

    private static final List<String> LAYERS = List.of("SCENE", "CITY", "WORLD", "PERSON");
    private static final List<String> CLAIM_STATUSES = List.of("DRAFT", "IN_REVIEW", "PUBLISHED", "RETRACTED");
    private static final List<String> SOURCE_STATUSES = List.of("PENDING", "VERIFIED", "REJECTED");

    private static final List<String> TASK_KEYS = List.of("task_id", "work_id", "title", "task_type", "status", "requested_by", "requested_role",
        "instructions", "requested_profile", "active_run_id", "created_at", "updated_at");
    private static final List<String> RUN_KEYS = List.of("run_id", "task_id", "mandate_id", "runtime", "profile_name", "profile_fingerprint", "status",
        "runtime_thread_id", "runtime_run_id", "reason", "created_at", "updated_at", "work_id", "requested_by", "requested_role");
    private static final List<String> PROPOSAL_KEYS = List.of("proposal_id", "work_id", "run_id", "task_id", "mandate_id", "status", "review_status",
        "review_id", "reviewed_by", "review_comment", "created_at", "applied_at", "proposal_json");
    private static final List<String> ITEM_KEYS = List.of("item_index", "decision", "reviewer", "comment", "created_at");
    private static final List<String> WORK_KEYS = List.of("work_id", "title", "status", "genre", "dynasty_id", "line_count", "version_count",
        "background_count", "annotation_count", "claim_count", "pending_source_count");
    private static final List<String> SOURCE_KEYS = List.of("id", "title", "author", "edition", "url", "rights_note", "source_kind", "reliability",
        "verification_status", "verified_by", "verified_at");
    private static final List<String> SOURCE_CITATION_KEYS = List.of("claim_id", "claim_value", "claim_kind", "claim_status", "locator", "evidence_excerpt");
    private static final List<String> CONTENT_KEYS = List.of("id", "entity_type", "slug", "title", "summary", "start_year", "end_year", "time_precision",
        "status", "revision", "reviewed_by");
    private static final List<String> WORK_INFO_KEYS = List.of("id", "genre", "dynasty_id", "creation_place_id");
    private static final List<String> VERSION_KEYS = List.of("id", "work_id", "version_code", "label", "script", "source_id", "source_locator", "status");
    private static final List<String> LINE_KEYS = List.of("version_id", "line_seq", "content", "pinyin");
    private static final List<String> CLAIM_KEYS = List.of("id", "subject_id", "property_key", "value_text", "claim_kind", "certainty", "status");
    private static final List<String> CITATION_KEYS = List.of("claim_id", "source_id", "locator", "evidence_excerpt", "verification_status");
    private static final List<String> BACKGROUND_KEYS = List.of("id", "work_id", "layer", "audience", "body_text", "claim_id");
    private static final List<String> ANNOTATION_KEYS = List.of("id", "version_id", "line_seq", "annotation_kind", "audience", "content", "claim_id");
    private static final List<String> SNAPSHOT_SOURCE_KEYS = List.of("id", "title", "author", "edition", "url", "rights_note", "source_kind",
        "reliability", "verification_status");
    private static final List<String> BACKGROUND_LINE_KEYS = List.of("background_id", "version_id", "line_seq");
    private static final List<String> COVERAGE_KEYS = List.of("id", "entity_type", "from_year", "to_year", "coverage_kind", "status", "note");

    private final PoetryStudioMapper mapper;
    private final PoetryAgentService domain;
    private final PoetryReviewService review;
    private final ObjectMapper json;

    public PoetryStudioService(PoetryStudioMapper mapper, PoetryAgentService domain, PoetryReviewService review, ObjectMapper json) {
        this.mapper = mapper; this.domain = domain; this.review = review; this.json = json;
    }

    /** 带 HTTP 语义的失败。控制器的 advice 把它翻译成统一信封。 */
    public static class Failure extends RuntimeException {
        private final int http; private final String status; private final String code; private final transient Object details;
        public Failure(int http, String status, String code, String message, Object details) { super(message); this.http = http; this.status = status; this.code = code; this.details = details; }
        public int http() { return http; }
        public String status() { return status; }
        public String code() { return code; }
        public Object details() { return details; }
        static Failure bad(String code, String message) { return new Failure(400, "REJECTED", code, message, null); }
        static Failure bad(String code, String message, Object details) { return new Failure(400, "REJECTED", code, message, details); }
        static Failure forbidden(String code, String message) { return new Failure(403, "FORBIDDEN", code, message, null); }
        static Failure notFound(String code, String message) { return new Failure(404, "NOT_FOUND", code, message, null); }
        static Failure conflict(String code, String message, Object details) { return new Failure(409, "CONFLICT", code, message, details); }
    }

    /** 写操作结果：data + 审计引用。 */
    public record Written(Map<String, Object> data, List<String> auditRefs) {}

    // =================================================================== 读

    public Map<String, Object> tasks(String workId, String status, String taskType, String limitRaw, String offsetRaw) {
        int[] p = page(limitRaw, offsetRaw);
        String w = optionalId(workId, "work_id"), s = optionalEnum(status, "status", 24), t = optionalEnum(taskType, "task_type", 32);
        return paged(rows(mapper.tasks(w, s, t, p[0] + 1, p[1]), TASK_KEYS), p[0], p[1]);
    }

    public Map<String, Object> taskRuns(String taskId) {
        requireId(taskId, "task id");
        if (n(mapper.taskExists(taskId)) == 0) throw Failure.notFound("TASK_NOT_FOUND", "task not found");
        return Map.of("items", rows(mapper.taskRuns(taskId), RUN_KEYS));
    }

    public Map<String, Object> proposals(String workId, String status, String reviewStatus, String runId, String taskId, String limitRaw, String offsetRaw) {
        int[] p = page(limitRaw, offsetRaw);
        return paged(rows(mapper.proposals(optionalId(workId, "work_id"), optionalEnum(status, "status", 24), optionalEnum(reviewStatus, "review_status", 24),
            optionalId(runId, "run_id"), optionalId(taskId, "task_id"), p[0] + 1, p[1]), PROPOSAL_KEYS), p[0], p[1]);
    }

    public Map<String, Object> proposalItems(String proposalId) {
        requireId(proposalId, "proposal id");
        if (n(mapper.proposalExists(proposalId)) == 0) throw Failure.notFound("PROPOSAL_NOT_FOUND", "proposal not found");
        return Map.of("items", rows(mapper.proposalItems(proposalId), ITEM_KEYS));
    }

    public Map<String, Object> works(String limitRaw, String offsetRaw) {
        int[] p = page(limitRaw, offsetRaw);
        return paged(rows(mapper.works(p[0] + 1, p[1]), WORK_KEYS), p[0], p[1]);
    }

    public Map<String, Object> sources(String verificationStatus, String limitRaw, String offsetRaw) {
        int[] p = page(limitRaw, offsetRaw);
        List<Map<String, Object>> fetched = rows(mapper.sources(optionalEnum(verificationStatus, "verification_status", 16), p[0] + 1, p[1]), SOURCE_KEYS);
        List<Map<String, Object>> pageRows = fetched.subList(0, Math.min(p[0], fetched.size()));
        List<String> ids = pageRows.stream().map(r -> (String) r.get("id")).toList();
        Map<String, List<Map<String, Object>>> bySource = new LinkedHashMap<>();
        if (!ids.isEmpty()) {
            for (Map<String, Object> raw : mapper.citationsOfSources(ids)) {
                Map<String, Object> c = row(raw, SOURCE_CITATION_KEYS);
                c.put("locator_state", PoetryStudioRules.locatorState((String) c.get("locator")).name());
                bySource.computeIfAbsent(String.valueOf(ci(raw, "source_id")), k -> new ArrayList<>()).add(c);
            }
        }
        List<Map<String, Object>> items = new ArrayList<>();
        for (Map<String, Object> r : pageRows) {
            Map<String, Object> item = new LinkedHashMap<>(r);
            item.put("citations", bySource.getOrDefault((String) r.get("id"), List.of()));
            items.add(item);
        }
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("items", items); out.put("limit", p[0]); out.put("offset", p[1]); out.put("has_more", fetched.size() > p[0]);
        return out;
    }

    public Map<String, Object> coverage(String workId) {
        requireWork(workId);
        Scope s = load(workId);
        GapReport gaps = domain.gaps(workId);

        Map<String, Object> totals = new LinkedHashMap<>();
        totals.put("lines", s.lines.size()); totals.put("versions", s.versions.size()); totals.put("backgrounds", s.backgrounds.size());
        totals.put("annotations", s.annotations.size()); totals.put("claims", s.claims.size()); totals.put("sources", s.sources.size());
        totals.put("citations", s.citations.size());

        Map<String, Object> claimsByStatus = new LinkedHashMap<>();
        CLAIM_STATUSES.forEach(k -> claimsByStatus.put(k, 0));
        for (Map<String, Object> c : s.claims) claimsByStatus.merge(String.valueOf(c.get("status")), 1, (a, b) -> (Integer) a + 1);

        // "checkable" = 至少有一条 citation 的 locator 是真实值(SET)。与来源是否已核验无关；核验另见 sources_by_verification。
        Set<Object> checkableClaims = new LinkedHashSet<>();
        for (Map<String, Object> c : s.citations)
            if (PoetryStudioRules.locatorState((String) c.get("locator")) == LocatorState.SET) checkableClaims.add(c.get("claim_id"));
        long checkable = s.claims.stream().filter(c -> checkableClaims.contains(c.get("id"))).count();
        Map<String, Object> claimsCheckable = new LinkedHashMap<>();
        claimsCheckable.put("checkable", checkable); claimsCheckable.put("total", s.claims.size());

        Map<String, Object> sourcesByVerification = new LinkedHashMap<>();
        SOURCE_STATUSES.forEach(k -> sourcesByVerification.put(k, 0));
        for (Map<String, Object> src : s.sources) sourcesByVerification.merge(String.valueOf(src.get("verification_status")), 1, (a, b) -> (Integer) a + 1);

        Map<String, String> layerOf = new LinkedHashMap<>();
        for (Map<String, Object> b : s.backgrounds) layerOf.put((String) b.get("id"), (String) b.get("layer"));
        Map<String, Set<String>> bgPerLine = new LinkedHashMap<>();
        Map<String, Set<String>> layersPerLine = new LinkedHashMap<>();
        Map<String, Set<String>> linesPerLayer = new LinkedHashMap<>();
        for (Map<String, Object> bl : s.backgroundLines) {
            String lineKey = bl.get("version_id") + "#" + num(bl.get("line_seq"));
            String layer = layerOf.get((String) bl.get("background_id"));
            bgPerLine.computeIfAbsent(lineKey, k -> new LinkedHashSet<>()).add((String) bl.get("background_id"));
            if (layer != null) {
                layersPerLine.computeIfAbsent(lineKey, k -> new LinkedHashSet<>()).add(layer);
                linesPerLayer.computeIfAbsent(layer, k -> new LinkedHashSet<>()).add(lineKey);
            }
        }
        Map<String, Object> layers = new LinkedHashMap<>();
        for (String layer : LAYERS) {
            Map<String, Object> entry = new LinkedHashMap<>();
            entry.put("count", s.backgrounds.stream().filter(b -> layer.equals(b.get("layer"))).count());
            entry.put("linked_lines", linesPerLayer.getOrDefault(layer, Set.of()).size());
            layers.put(layer, entry);
        }

        Map<String, Integer> annotationsPerLine = new LinkedHashMap<>();
        for (Map<String, Object> a : s.annotations) annotationsPerLine.merge(a.get("version_id") + "#" + num(a.get("line_seq")), 1, Integer::sum);
        List<Map<String, Object>> lines = new ArrayList<>();
        for (Map<String, Object> l : s.lines) {
            String key = l.get("version_id") + "#" + num(l.get("line_seq"));
            Map<String, Object> entry = new LinkedHashMap<>();
            entry.put("version_id", l.get("version_id")); entry.put("line_seq", l.get("line_seq")); entry.put("content", l.get("content"));
            entry.put("annotation_count", annotationsPerLine.getOrDefault(key, 0));
            entry.put("background_count", bgPerLine.getOrDefault(key, Set.of()).size());
            Set<String> present = layersPerLine.getOrDefault(key, Set.of());
            entry.put("layers", LAYERS.stream().filter(present::contains).toList());
            lines.add(entry);
        }

        Set<String> gapCodes = new LinkedHashSet<>();
        for (Gap g : gaps.gaps()) gapCodes.add(g.code());

        Map<String, Object> publication = new LinkedHashMap<>();
        publication.put("work_status", s.work.get("status"));
        publication.put("published_claims", s.claims.stream().filter(c -> "PUBLISHED".equals(c.get("status"))).count());
        publication.put("audit_checks", gaps.auditChecks()); publication.put("audit_non_zero", gaps.auditNonZero());

        Map<String, Object> out = new LinkedHashMap<>();
        out.put("work_id", workId); out.put("totals", totals); out.put("claims_by_status", claimsByStatus);
        out.put("claims_checkable", claimsCheckable); out.put("sources_by_verification", sourcesByVerification);
        out.put("layers", layers); out.put("lines", lines); out.put("gap_codes", new ArrayList<>(gapCodes)); out.put("publication", publication);
        return out;
    }

    public Map<String, Object> studioView(String workId) {
        requireWork(workId);
        Scope s = load(workId);
        GapReport gaps = domain.gaps(workId);

        Map<String, Object> out = new LinkedHashMap<>();
        out.put("work", s.work); out.put("work_info", s.info); out.put("versions", s.versions); out.put("lines", s.lines);
        out.put("claims", s.claims); out.put("citations", s.citations); out.put("backgrounds", s.backgrounds);
        out.put("annotations", s.annotations); out.put("sources", s.sources);
        out.put("background_lines", s.backgroundLines);
        out.put("claim_status_by_id", idToStatus(s.claims, "id", "status"));
        Map<String, Object> contentStatus = new LinkedHashMap<>();
        contentStatus.put(workId, s.work.get("status"));
        for (Map<String, Object> r : s.backgroundContentStatus) contentStatus.put(String.valueOf(r.get("id")), r.get("status"));
        out.put("content_status_by_id", contentStatus);
        out.put("version_status_by_id", idToStatus(s.versions, "id", "status"));
        out.put("source_verification_by_id", idToStatus(s.sources, "id", "verification_status"));
        out.put("coverage_rows", s.coverageRows);
        Map<String, Object> gapReport = new LinkedHashMap<>();
        gapReport.put("work_id", gaps.workId());
        List<Map<String, Object>> gapList = new ArrayList<>();
        for (Gap g : gaps.gaps()) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("code", g.code()); m.put("severity", g.severity()); m.put("message", g.message()); m.put("target_ref", g.targetRef());
            gapList.add(m);
        }
        gapReport.put("gaps", gapList); gapReport.put("audit_checks", gaps.auditChecks()); gapReport.put("audit_non_zero", gaps.auditNonZero());
        out.put("gap_report", gapReport);
        return out;
    }

    // =================================================================== 写

    @Transactional
    public Written setLocator(String claimId, String sourceId, LocatorUpdate body) {
        if (body == null) throw Failure.bad("BODY_REQUIRED", "request body is required");
        requireId(claimId, "claim id"); requireId(sourceId, "source id");
        String reviewer = requireSourceReviewer(body.reviewer(), body.reviewerRole());
        String problem = PoetryStudioRules.locatorProblem(body.locator());
        if (problem != null) throw Failure.bad("INVALID_LOCATOR", problem);
        String locator = PoetryStudioRules.normalizeText(body.locator());
        String excerpt = optionalText(body.evidenceExcerpt(), "evidence_excerpt", PoetryStudioRules.EXCERPT_MAX);
        String note = optionalText(body.note(), "note", PoetryStudioRules.NOTE_MAX);

        Map<String, Object> existing = mapper.citation(claimId, sourceId);
        if (existing == null) throw Failure.notFound("CITATION_NOT_FOUND", "citation not found for this claim and source; this endpoint only edits an existing citation");
        String previous = (String) ci(existing, "locator");
        String keptExcerpt = excerpt != null ? excerpt : (String) ci(existing, "evidence_excerpt");
        mapper.updateCitation(claimId, sourceId, locator, keptExcerpt);
        // 来源的 verification_status 不动：写 locator 不等于核验。
        String logNote = (note == null ? "" : note + " | ") + "previous_locator=" + (previous == null ? "" : previous);
        long id = log("SET_LOCATOR", sourceId, claimId, null, locator, keptExcerpt, null, reviewer, body.reviewerRole(), logNote);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("claim_id", claimId); data.put("source_id", sourceId); data.put("locator", locator);
        data.put("locator_state", LocatorState.SET.name()); data.put("evidence_excerpt", keptExcerpt);
        data.put("source_verification_status", mapper.sourceStatus(sourceId));
        return new Written(data, List.of(logRef(id), "citation:" + claimId + "/" + sourceId));
    }

    @Transactional
    public Written verifySource(String sourceId, SourceVerification body) {
        if (body == null) throw Failure.bad("BODY_REQUIRED", "request body is required");
        requireId(sourceId, "source id");
        String decision = body.decision();
        if (!"VERIFY".equals(decision) && !"REJECT".equals(decision)) throw Failure.bad("INVALID_DECISION", "decision must be VERIFY or REJECT");
        String reviewer = requireSourceReviewer(body.reviewer(), body.reviewerRole());
        String note = optionalText(body.note(), "note", PoetryStudioRules.NOTE_MAX);
        String status = mapper.sourceStatus(sourceId);
        if (status == null) throw Failure.notFound("SOURCE_NOT_FOUND", "source not found");
        String stamped = "[studio:" + body.reviewerRole() + "] " + (note == null ? ("VERIFY".equals(decision) ? "人工核验来源" : "人工驳回来源") : note);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("source_id", sourceId); data.put("decision", decision);
        if ("REJECT".equals(decision)) {
            if ("REJECTED".equals(status)) return unchanged(data, status);
            // Rejecting a source that PUBLISHED content still rests on would make every later publish fail the
            // audit with no hint why. Say so now, and name what has to be retracted first (review item A-13).
            List<Map<String, Object>> dependents = mapper.publishedDependentsOfSource(sourceId);
            if (!dependents.isEmpty()) {
                List<Map<String, Object>> shown = new ArrayList<>();
                for (Map<String, Object> dep : dependents) {
                    if (shown.size() >= 20) break;
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("kind", ci(dep, "kind")); m.put("id", ci(dep, "ref_id"));
                    shown.add(m);
                }
                throw Failure.conflict("SOURCE_IN_USE", "cannot reject: published content still depends on this source; retract that content first",
                    Map.of("dependents", shown, "dependent_count", dependents.size()));
            }
            PoetryReviewService.Decision d = review.retract("source", sourceId, reviewer, stamped);
            if (!d.accepted()) throw Failure.conflict("RETRACT_BLOCKED", "source rejection was refused", Map.of("blocking", d.blocking()));
        } else {
            if ("VERIFIED".equals(status)) return unchanged(data, status);
            List<Map<String, Object>> citations = mapper.citationsOfSource(sourceId);
            List<Map<String, Object>> baseTexts = mapper.textVersionsOfSource(sourceId);
            // "Every citation has a locator" is vacuously true for a source nothing uses. Verifying it would
            // vouch for nothing, so refuse until something actually cites it (review item A-13).
            if (citations.isEmpty() && baseTexts.isEmpty())
                throw Failure.conflict("NOTHING_TO_VERIFY", "no citation or text version uses this source, so there is no locator to check; cite it first", null);
            List<Map<String, Object>> missing = new ArrayList<>();
            for (Map<String, Object> c : citations) {
                LocatorState state = PoetryStudioRules.locatorState((String) ci(c, "locator"));
                if (state != LocatorState.SET) {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("claim_id", ci(c, "claim_id")); m.put("locator_state", state.name());
                    missing.add(m);
                }
            }
            if (!missing.isEmpty())
                throw Failure.conflict("LOCATOR_MISSING", "cannot verify: every citation of this source needs a real locator first", Map.of("missing", missing));
            PoetryReviewService.Decision d;
            try { d = review.publish("source", sourceId, reviewer, stamped); }
            catch (IllegalStateException ex) { throw Failure.conflict("AUDIT_ROLLBACK", ex.getMessage(), null); }
            if (!d.accepted())
                throw Failure.conflict("PUBLISH_BLOCKED", "source verification blocked by the publication gate or the integrity audit",
                    Map.of("blocking", d.blocking(), "audit_checks", d.auditChecks()));
            data.put("audit_checks", d.auditChecks());
            // Not a blocker: a text version's own source_locator cannot be entered through Studio yet, so refusing
            // here would leave no way forward. Report it so the reviewer knows it is still unchecked.
            List<Map<String, Object>> unlocatedTexts = new ArrayList<>();
            for (Map<String, Object> v : baseTexts) {
                LocatorState state = PoetryStudioRules.locatorState((String) ci(v, "source_locator"));
                if (state != LocatorState.SET) {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("version_id", ci(v, "id")); m.put("locator_state", state.name());
                    unlocatedTexts.add(m);
                }
            }
            if (!unlocatedTexts.isEmpty()) data.put("unlocated_text_versions", unlocatedTexts);
        }
        long id = log("VERIFY".equals(decision) ? "VERIFY_SOURCE" : "REJECT_SOURCE", sourceId, null, null, null, null, decision, reviewer, body.reviewerRole(), note);
        data.put("verification_status", mapper.sourceStatus(sourceId)); data.put("changed", true);
        return new Written(data, List.of(logRef(id), "source:" + sourceId));
    }

    @Transactional
    public Written putItemDecisions(String proposalId, ItemDecisions body) {
        if (body == null) throw Failure.bad("BODY_REQUIRED", "request body is required");
        requireId(proposalId, "proposal id");
        String role = body.reviewerRole();
        if (role == null || !PoetryStudioRules.ITEM_REVIEW_ROLES.contains(role))
            throw Failure.bad("INVALID_ROLE", "reviewer_role must be one of HISTORICAL_REVIEWER, PLATFORM_ADMIN, CONTENT_EDITOR");
        String reviewer = requireReviewer(body.reviewer());
        List<ItemDecision> decisions = body.decisions();
        if (decisions == null || decisions.isEmpty()) throw Failure.bad("DECISIONS_REQUIRED", "decisions must contain at least one item");
        if (decisions.size() > MAX_ITEMS) throw Failure.bad("TOO_MANY_DECISIONS", "decisions may contain at most " + MAX_ITEMS + " items");

        // 行锁：与整体评审串行；先锁再读状态。
        String reviewStatus = mapper.lockProposalReviewStatus(proposalId);
        if (reviewStatus == null) throw Failure.notFound("PROPOSAL_NOT_FOUND", "proposal not found");
        if (!"PENDING".equals(reviewStatus))
            throw Failure.conflict("PROPOSAL_NOT_PENDING", "item decisions can only be written while review_status is PENDING (is " + reviewStatus + ")", null);
        JsonNode changes;
        try { changes = json.readTree(mapper.proposalJson(proposalId)).path("changes"); }
        catch (Exception ex) { throw Failure.bad("PROPOSAL_UNREADABLE", "stored proposal JSON is unreadable"); }
        int size = changes.size();

        Set<Integer> seen = new LinkedHashSet<>();
        StringBuilder summary = new StringBuilder();
        List<Object[]> validated = new ArrayList<>();
        for (ItemDecision d : decisions) {
            if (d == null || d.itemIndex() == null) throw Failure.bad("INVALID_ITEM_INDEX", "item_index is required");
            double raw = d.itemIndex().doubleValue();
            if (raw != Math.rint(raw)) throw Failure.bad("INVALID_ITEM_INDEX", "item_index must be an integer");
            int index = (int) raw;
            if (index < 0 || index >= size) throw Failure.bad("INVALID_ITEM_INDEX", "item_index " + index + " is outside the proposal's changes (0.." + (size - 1) + ")");
            if (!seen.add(index)) throw Failure.bad("DUPLICATE_ITEM_INDEX", "item_index " + index + " appears more than once");
            if (!"APPROVE".equals(d.decision()) && !"REJECT".equals(d.decision()))
                throw Failure.bad("INVALID_DECISION", "decision must be APPROVE or REJECT (item " + index + ")");
            String comment = optionalText(d.comment(), "comment", PoetryStudioRules.NOTE_MAX);
            validated.add(new Object[]{index, d.decision(), comment});
            if (summary.length() > 0) summary.append(',');
            summary.append(index).append(':').append(d.decision());
        }
        for (Object[] v : validated) {
            int affected = mapper.itemUpdate(proposalId, (Integer) v[0], (String) v[1], reviewer, (String) v[2]);
            // 先 UPDATE 再 INSERT：MySQL 默认"受影响行数"在值未变时为 0，所以 0 行时再确认一次是否真的不存在。
            if (affected == 0 && !itemExists(proposalId, (Integer) v[0]))
                mapper.itemInsert(proposalId, (Integer) v[0], (String) v[1], reviewer, (String) v[2]);
        }
        long id = log("ITEM_DECISIONS", null, null, proposalId, null, null, null, reviewer, role, summary.toString());

        int executable = 0;
        for (JsonNode c : changes) { JsonNode p = c.path("draft_payload"); if (!p.isMissingNode() && !p.isNull()) executable++; }
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("proposal_id", proposalId); data.put("executable_count", executable); data.put("recorded", validated.size());
        data.put("items", rows(mapper.proposalItems(proposalId), ITEM_KEYS));
        return new Written(data, List.of(logRef(id), "agent-proposal:" + proposalId));
    }

    // =================================================================== 内部

    private boolean itemExists(String proposalId, int index) {
        for (Map<String, Object> r : mapper.proposalItems(proposalId)) if (num(ci(r, "item_index")) == index) return true;
        return false;
    }

    private Written unchanged(Map<String, Object> data, String status) {
        data.put("verification_status", status); data.put("changed", false);
        return new Written(data, List.of("source:" + data.get("source_id")));
    }

    private long log(String action, String sourceId, String claimId, String proposalId, String locator, String excerpt, String decision,
                     String reviewer, String role, String note) {
        LogEntry e = new LogEntry();
        e.setAction(action); e.setSourceId(sourceId); e.setClaimId(claimId); e.setProposalId(proposalId); e.setLocator(locator);
        e.setEvidenceExcerpt(excerpt); e.setDecision(decision); e.setReviewer(reviewer); e.setReviewerRole(role); e.setNote(note);
        mapper.insertLog(e);
        return e.getId() == null ? -1L : e.getId();
    }
    private static String logRef(long id) { return id < 0 ? "studio-check-log" : "studio-check-log:" + id; }

    /** 核验/填 locator：角色必须是 HISTORICAL_REVIEWER/PLATFORM_ADMIN，再验署名。返回清洗后的署名。 */
    private static String requireSourceReviewer(String reviewer, String role) {
        if (role == null || !PoetryStudioRules.ITEM_REVIEW_ROLES.contains(role))
            throw Failure.bad("INVALID_ROLE", "reviewer_role must be one of HISTORICAL_REVIEWER, PLATFORM_ADMIN, CONTENT_EDITOR");
        if (!PoetryStudioRules.SOURCE_REVIEW_ROLES.contains(role))
            throw Failure.forbidden("ROLE_NOT_ALLOWED", "only HISTORICAL_REVIEWER or PLATFORM_ADMIN may fill locators or verify sources");
        return requireReviewer(reviewer);
    }

    private static String requireReviewer(String reviewer) {
        List<String> problems = PoetryStudioRules.reviewerProblems(reviewer);
        if (!problems.isEmpty()) throw Failure.bad("INVALID_REVIEWER", problems.get(0), problems);
        return PoetryStudioRules.cleanReviewer(reviewer);
    }

    private static String optionalText(String raw, String field, int max) {
        if (raw == null) return null;
        String s = PoetryStudioRules.normalizeText(raw);
        if (s.isEmpty()) return null;
        if (s.codePointCount(0, s.length()) > max) throw Failure.bad("FIELD_TOO_LONG", field + " is longer than " + max + " characters");
        return s;
    }

    private void requireWork(String workId) {
        requireId(workId, "work id");
        if (n(mapper.workExists(workId)) == 0) throw Failure.notFound("WORK_NOT_FOUND", "work not found");
    }

    private static void requireId(String id, String what) {
        if (id == null || !id.matches(PoetryStudioRules.ID_PATTERN)) throw Failure.bad("INVALID_ID", "invalid " + what);
    }
    private static String optionalId(String v, String name) {
        if (v == null || v.isBlank()) return "";
        if (!v.matches(PoetryStudioRules.ID_PATTERN)) throw Failure.bad("INVALID_FILTER", "invalid " + name);
        return v;
    }
    private static String optionalEnum(String v, String name, int max) {
        if (v == null || v.isBlank()) return "";
        if (!v.matches("[A-Z][A-Z_]{0," + (max - 1) + "}")) throw Failure.bad("INVALID_FILTER", "invalid " + name);
        return v;
    }

    private static int[] page(String limitRaw, String offsetRaw) {
        return new int[]{intParam(limitRaw, "limit", DEFAULT_LIMIT, 1, MAX_LIMIT), intParam(offsetRaw, "offset", 0, 0, 1_000_000)};
    }
    private static int intParam(String raw, String name, int def, int min, int max) {
        if (raw == null || raw.isBlank()) return def;
        int v;
        try { v = Integer.parseInt(raw.trim()); }
        catch (NumberFormatException ex) { throw Failure.bad("INVALID_PAGINATION", name + " must be an integer"); }
        if (v < min || v > max) throw Failure.bad("INVALID_PAGINATION", name + " must be between " + min + " and " + max);
        return v;
    }

    /** rows 已多取 1 条用于判断 has_more。 */
    private static Map<String, Object> paged(List<Map<String, Object>> fetched, int limit, int offset) {
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("items", new ArrayList<>(fetched.subList(0, Math.min(limit, fetched.size()))));
        out.put("limit", limit); out.put("offset", offset); out.put("has_more", fetched.size() > limit);
        return out;
    }

    private static Map<String, Object> idToStatus(List<Map<String, Object>> rows, String idKey, String statusKey) {
        Map<String, Object> out = new LinkedHashMap<>();
        for (Map<String, Object> r : rows) out.put(String.valueOf(r.get(idKey)), r.get(statusKey));
        return out;
    }

    private record Scope(Map<String, Object> work, Map<String, Object> info, List<Map<String, Object>> versions, List<Map<String, Object>> lines,
                         List<Map<String, Object>> claims, List<Map<String, Object>> citations, List<Map<String, Object>> backgrounds,
                         List<Map<String, Object>> backgroundLines, List<Map<String, Object>> backgroundContentStatus,
                         List<Map<String, Object>> annotations, List<Map<String, Object>> sources, List<Map<String, Object>> coverageRows) {}

    private Scope load(String workId) {
        Map<String, Object> work = mapper.workContent(workId);
        if (work == null) throw Failure.notFound("WORK_NOT_FOUND", "work not found");
        return new Scope(row(work, CONTENT_KEYS), row(mapper.workInfo(workId), WORK_INFO_KEYS),
            rows(mapper.scopeVersions(workId), VERSION_KEYS), rows(mapper.scopeLines(workId), LINE_KEYS),
            rows(mapper.scopeClaims(workId), CLAIM_KEYS), rows(mapper.scopeCitations(workId), CITATION_KEYS),
            rows(mapper.scopeBackgrounds(workId), BACKGROUND_KEYS), rows(mapper.scopeBackgroundLines(workId), BACKGROUND_LINE_KEYS),
            rows(mapper.scopeBackgroundContentStatus(workId), List.of("id", "status")),
            rows(mapper.scopeAnnotations(workId), ANNOTATION_KEYS), rows(mapper.scopeSources(workId), SNAPSHOT_SOURCE_KEYS),
            rows(mapper.coverageRows(), COVERAGE_KEYS));
    }

    // ---- 行规范化：固定键集合(MyBatis 默认丢弃 NULL 列)、键名大小写不敏感、时间转 ISO-8601 UTC ----

    private static List<Map<String, Object>> rows(List<Map<String, Object>> raw, List<String> keys) {
        List<Map<String, Object>> out = new ArrayList<>(raw.size());
        for (Map<String, Object> r : raw) out.add(row(r, keys));
        return out;
    }

    private static Map<String, Object> row(Map<String, Object> raw, List<String> keys) {
        Map<String, Object> folded = new TreeMap<>(String.CASE_INSENSITIVE_ORDER);
        if (raw != null) folded.putAll(raw);
        Map<String, Object> out = new LinkedHashMap<>();
        for (String k : keys) out.put(k, iso(folded.get(k)));
        return out;
    }

    private static Object ci(Map<String, Object> raw, String key) {
        for (Map.Entry<String, Object> e : raw.entrySet()) if (e.getKey().equalsIgnoreCase(key)) return iso(e.getValue());
        return null;
    }

    static Object iso(Object v) {
        if (v == null) return null;
        if (v instanceof java.sql.Timestamp t) return t.toInstant().toString();
        if (v instanceof java.sql.Date d) return d.toLocalDate().toString();
        if (v instanceof java.sql.Time t) return t.toLocalTime().toString();
        if (v instanceof java.util.Date d) return Instant.ofEpochMilli(d.getTime()).toString();
        if (v instanceof LocalDateTime l) return l.atZone(ZoneId.systemDefault()).toInstant().toString();
        if (v instanceof OffsetDateTime o) return o.toInstant().toString();
        if (v instanceof Instant i) return i.toString();
        if (v instanceof Clob c) {
            try { return c.getSubString(1, (int) c.length()); } catch (Exception ex) { return null; }
        }
        return v;
    }

    private static int num(Object v) { return v instanceof Number n ? n.intValue() : Integer.parseInt(String.valueOf(v)); }
    private static int n(Integer v) { return v == null ? 0 : v; }
}
