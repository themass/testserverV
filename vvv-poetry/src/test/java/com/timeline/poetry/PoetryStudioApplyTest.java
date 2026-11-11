package com.timeline.poetry;

import com.fasterxml.jackson.databind.JsonNode;
import com.timeline.poetry.api.PoetryAgentModels.AgentResponse;
import com.timeline.poetry.api.PoetryAgentModels.ProposalApply;
import com.timeline.poetry.api.PoetryStudioModels.ItemDecision;
import com.timeline.poetry.api.PoetryStudioModels.ItemDecisions;
import com.timeline.poetry.service.PoetryAgentService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import java.util.List;
import java.util.Map;
import static org.junit.jupiter.api.Assertions.*;

/**
 * PoetryAgentService.apply 的逐项评审行为：没有逐项记录且提案含可执行项 -> 拒绝；
 * 有逐项记录 -> 只执行被明确 APPROVE 的可执行项。proposal 的 3 个 change：0、1 可执行，2 不可执行。
 */
class PoetryStudioApplyTest {
    PoetryStudioFixture fx;

    @BeforeEach void setUp() throws Exception { fx = new PoetryStudioFixture(); }

    private void decide(String proposalId, Object... pairs) {
        List<ItemDecision> decisions = new java.util.ArrayList<>();
        for (int i = 0; i < pairs.length; i += 2) decisions.add(new ItemDecision((Number) pairs[i], (String) pairs[i + 1], null));
        fx.studio.putItemDecisions(proposalId, new ItemDecisions(decisions, "Li Na", "CONTENT_EDITOR"));
    }

    private int annotationCount(String proposalId) {
        return fx.jdbc.queryForObject("SELECT COUNT(*) FROM poetry_annotation WHERE id LIKE ?", Integer.class, "ann-" + proposalId + "-%");
    }

    @Test void withoutAnyItemRecordApplyIsRefused() throws Exception {
        // 旧行为是"全部执行"。那等于 agent 造提案、自批、一次性应用，逐项评审形同虚设(A-05)。
        fx.seedProposal("proposal_leg");
        fx.approveProposal("proposal_leg", "review_leg");
        assertThrows(RuntimeException.class, () ->
            fx.agent.apply(fx.contextFor("proposal_leg", "idem-leg"), "proposal_leg", new ProposalApply("review_leg")),
            "executable changes with no per-item decisions must be refused");
        assertEquals(0, annotationCount("proposal_leg"), "nothing may be written");
        assertEquals("APPROVED", fx.jdbc.queryForObject("SELECT status FROM poetry_agent_proposal WHERE id='proposal_leg'", String.class),
            "a refused apply must leave the proposal as it was");
    }

    @Test void onlyExplicitlyApprovedExecutableItemsAreApplied() throws Exception {
        fx.seedProposal("proposal_one");
        decide("proposal_one", 0, "APPROVE", 1, "REJECT", 2, "APPROVE");
        fx.approveProposal("proposal_one", "review_one");
        AgentResponse<Map<String, Object>> r = fx.agent.apply(fx.contextFor("proposal_one", "idem-one"), "proposal_one", new ProposalApply("review_one"));
        assertEquals(List.of("CREATE_ANNOTATION:ann-proposal_one-a"), r.data().get("applied_operations"));
        assertEquals(List.of("1:REJECT"), r.data().get("skipped_executable_changes"));
        assertEquals(List.of("GAP_REPORT"), r.data().get("retained_editorial_changes"), "a non-executable item is retained whatever its decision");
        assertEquals(true, r.data().get("item_review"));
        assertEquals(1, annotationCount("proposal_one"));
        assertEquals(0, fx.jdbc.queryForObject("SELECT COUNT(*) FROM poetry_annotation WHERE id='ann-proposal_one-b'", Integer.class));
    }

    @Test void anExecutableItemWithoutADecisionIsSkippedOnceAnyItemIsRecorded() throws Exception {
        fx.seedProposal("proposal_partial");
        decide("proposal_partial", 1, "APPROVE");
        fx.approveProposal("proposal_partial", "review_partial");
        AgentResponse<Map<String, Object>> r = fx.agent.apply(fx.contextFor("proposal_partial", "idem-partial"), "proposal_partial", new ProposalApply("review_partial"));
        assertEquals(List.of("CREATE_ANNOTATION:ann-proposal_partial-b"), r.data().get("applied_operations"));
        assertEquals(List.of("0:UNDECIDED"), r.data().get("skipped_executable_changes"));
    }

    @Test void rejectingEveryExecutableItemAppliesNothingButStillCompletes() throws Exception {
        fx.seedProposal("proposal_none");
        decide("proposal_none", 0, "REJECT", 1, "REJECT");
        fx.approveProposal("proposal_none", "review_none");
        AgentResponse<Map<String, Object>> r = fx.agent.apply(fx.contextFor("proposal_none", "idem-none"), "proposal_none", new ProposalApply("review_none"));
        assertEquals(List.of(), r.data().get("applied_operations"));
        assertEquals(List.of("0:REJECT", "1:REJECT"), r.data().get("skipped_executable_changes"));
        assertEquals(0, annotationCount("proposal_none"));
    }

    @Test void applyIsStillIdempotentForTheSameKey() throws Exception {
        fx.seedProposal("proposal_idem");
        decide("proposal_idem", 0, "APPROVE", 1, "APPROVE");
        fx.approveProposal("proposal_idem", "review_idem");
        PoetryAgentService.Context ctx = fx.contextFor("proposal_idem", "idem-key");
        AgentResponse<Map<String, Object>> first = fx.agent.apply(ctx, "proposal_idem", new ProposalApply("review_idem"));
        AgentResponse<Map<String, Object>> second = fx.agent.apply(ctx, "proposal_idem", new ProposalApply("review_idem"));
        assertEquals(first.data().get("application_id"), second.data().get("application_id"));
        assertEquals(true, second.data().get("idempotent"));
        assertEquals(2, annotationCount("proposal_idem"));
    }

    @Test void applyFailsClosedWhenTheItemTableIsMissing() throws Exception {
        fx.seedProposal("proposal_missing_table");
        fx.approveProposal("proposal_missing_table", "review_mt");
        fx.jdbc.execute("DROP TABLE poetry_agent_proposal_item");
        assertThrows(RuntimeException.class, () ->
            fx.agent.apply(fx.contextFor("proposal_missing_table", "idem-mt"), "proposal_missing_table", new ProposalApply("review_mt")),
            "V009 not applied must not silently fall back to 'execute everything'");
        assertEquals(0, annotationCount("proposal_missing_table"));
    }

    @Test void theItemDecisionsHttpRouteAndApplyAgree() throws Exception {
        PoetryStudioHttp http = new PoetryStudioHttp(fx);
        fx.seedProposal("proposal_http");
        JsonNode put = http.send(http.studioPut("/proposals/proposal_http/items", PoetryStudioHttp.map("reviewer", "Li Na", "reviewer_role", "CONTENT_EDITOR",
            "decisions", List.of(PoetryStudioHttp.map("item_index", 0, "decision", "APPROVE"), PoetryStudioHttp.map("item_index", 1, "decision", "REJECT")))), 200);
        assertEquals(2, put.path("data").path("recorded").asInt());
        fx.approveProposal("proposal_http", "review_http");
        AgentResponse<Map<String, Object>> r = fx.agent.apply(fx.contextFor("proposal_http", "idem-http"), "proposal_http", new ProposalApply("review_http"));
        assertEquals(List.of("CREATE_ANNOTATION:ann-proposal_http-a"), r.data().get("applied_operations"));
    }
}
