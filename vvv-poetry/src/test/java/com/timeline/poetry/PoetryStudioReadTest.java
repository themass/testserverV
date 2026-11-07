package com.timeline.poetry;

import com.fasterxml.jackson.databind.JsonNode;
import com.timeline.poetry.service.AuditRunner;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;
import static com.timeline.poetry.PoetryStudioHttp.*;
import static org.junit.jupiter.api.Assertions.*;

/** 读路由：列表过滤、分页上限、coverage / studio-view 形状。数字来自真实的 V002+V004 种子（《春望》）。 */
class PoetryStudioReadTest {
    private static final String WORK = "work-chun-wang";
    PoetryStudioFixture fx;
    PoetryStudioHttp http;

    @BeforeEach void setUp() throws Exception { fx = new PoetryStudioFixture(); http = new PoetryStudioHttp(fx); }

    private static Set<String> set(String... v) { return new TreeSet<>(List.of(v)); }
    private static List<String> texts(JsonNode array, String field) {
        List<String> out = new ArrayList<>();
        // field 为空串时，array 的元素本身就是字符串
        array.forEach(n -> out.add(field.isEmpty() ? n.asText() : n.path(field).asText()));
        return out;
    }

    // ------------------------------------------------------------------ 任务

    @Test void tasksAreNewestFirstAndFilterable() throws Exception {
        fx.seedTask("task_a", WORK, "GAP_ANALYSIS", "COMPLETED", "2026-11-01 10:00:00");
        fx.seedTask("task_b", WORK, "ANNOTATION_DRAFT", "RUNNING", "2026-11-02 10:00:00");
        fx.seedTask("task_c", "work-other", "GAP_ANALYSIS", "RUNNING", "2026-11-03 10:00:00");
        JsonNode all = http.data("/tasks", 200);
        assertEquals(List.of("task_c", "task_b", "task_a"), texts(all.path("items"), "task_id"));
        assertEquals(50, all.path("limit").asInt());
        assertEquals(0, all.path("offset").asInt());
        assertFalse(all.path("has_more").asBoolean());
        assertEquals(set("task_id", "work_id", "title", "task_type", "status", "requested_by", "requested_role", "instructions",
            "requested_profile", "active_run_id", "created_at", "updated_at"), keys(all.path("items").get(0)));
        assertTrue(all.path("items").get(0).has("active_run_id"), "null columns still appear as keys");
        assertTrue(all.path("items").get(0).path("active_run_id").isNull());

        assertEquals(List.of("task_c", "task_b"), texts(http.data("/tasks?status=RUNNING", 200).path("items"), "task_id"));
        assertEquals(List.of("task_c", "task_a"), texts(http.data("/tasks?task_type=GAP_ANALYSIS", 200).path("items"), "task_id"));
        assertEquals(List.of("task_a"), texts(http.data("/tasks?work_id=" + WORK + "&task_type=GAP_ANALYSIS", 200).path("items"), "task_id"));
        assertTrue(http.data("/tasks?work_id=work-nothing", 200).path("items").isEmpty());
    }

    @Test void paginationReportsHasMoreAndRejectsOutOfRange() throws Exception {
        fx.seedTask("task_a", WORK, "GAP_ANALYSIS", "COMPLETED", "2026-11-01 10:00:00");
        fx.seedTask("task_b", WORK, "GAP_ANALYSIS", "COMPLETED", "2026-11-02 10:00:00");
        fx.seedTask("task_c", WORK, "GAP_ANALYSIS", "COMPLETED", "2026-11-03 10:00:00");
        JsonNode first = http.data("/tasks?limit=2", 200);
        assertEquals(List.of("task_c", "task_b"), texts(first.path("items"), "task_id"));
        assertTrue(first.path("has_more").asBoolean());
        JsonNode second = http.data("/tasks?limit=2&offset=2", 200);
        assertEquals(List.of("task_a"), texts(second.path("items"), "task_id"));
        assertFalse(second.path("has_more").asBoolean());
        for (String bad : List.of("limit=0", "limit=201", "limit=-1", "limit=abc", "offset=-1", "offset=x"))
            assertEquals("INVALID_PAGINATION", http.send(http.agentGet("/tasks?" + bad), 400).path("data").path("code").asText(), bad);
        for (String bad : List.of("status=running", "status=DROP TABLE", "task_type=x%27", "work_id=a", "work_id=a%20b"))
            assertEquals("INVALID_FILTER", http.send(http.agentGet("/tasks?" + bad), 400).path("data").path("code").asText(), bad);
    }

    @Test void limitIsCappedAt200AndDefaultsTo50() throws Exception {
        List<Object[]> rows = new ArrayList<>();
        for (int i = 0; i < 205; i++)
            rows.add(new Object[]{String.format("task_%03d", i), WORK, "GAP_ANALYSIS", "Li Na", "COMPLETED", "t", "i", "authoring", "CONTENT_EDITOR"});
        fx.jdbc.batchUpdate("INSERT INTO poetry_agent_task (id,work_id,task_type,requested_by,status,title,instructions,requested_profile,requested_role) VALUES (?,?,?,?,?,?,?,?,?)", rows);
        JsonNode max = http.data("/tasks?limit=200", 200);
        assertEquals(200, max.path("items").size());
        assertTrue(max.path("has_more").asBoolean());
        JsonNode def = http.data("/tasks", 200);
        assertEquals(50, def.path("items").size());
        assertEquals(50, def.path("limit").asInt());
        assertEquals(5, http.data("/tasks?limit=200&offset=200", 200).path("items").size());
    }

    @Test void taskRunsListsRunsOfThatTaskOnly() throws Exception {
        fx.seedTask("task_a", WORK, "GAP_ANALYSIS", "COMPLETED", "2026-11-01 10:00:00");
        fx.seedTask("task_b", WORK, "GAP_ANALYSIS", "COMPLETED", "2026-11-01 11:00:00");
        fx.seedRun("run_a1", "task_a");
        fx.seedRun("run_b1", "task_b");
        JsonNode runs = http.data("/tasks/task_a/runs", 200).path("items");
        assertEquals(List.of("run_a1"), texts(runs, "run_id"));
        assertEquals(set("run_id", "task_id", "mandate_id", "runtime", "profile_name", "profile_fingerprint", "status", "runtime_thread_id",
            "runtime_run_id", "reason", "created_at", "updated_at", "work_id", "requested_by", "requested_role"), keys(runs.get(0)));
        assertEquals("TASK_NOT_FOUND", http.send(http.agentGet("/tasks/task_none/runs"), 404).path("data").path("code").asText());
    }

    // ------------------------------------------------------------------ 提案

    @Test void proposalsFilterByStatusRunAndTaskAndKeepOrphans() throws Exception {
        fx.seedProposal("proposal_a");                       // 没有 run 行：task_id 为 null，但仍要出现在列表里
        fx.seedTask("task_b", WORK, "ANNOTATION_DRAFT", "RUNNING", "2026-11-02 10:00:00");
        fx.seedRun("run_proposal_b", "task_b");
        fx.seedProposal("proposal_b");
        fx.approveProposal("proposal_b", "review_b");

        JsonNode all = http.data("/proposals", 200);
        assertEquals(2, all.path("items").size());
        assertEquals(set("proposal_id", "work_id", "run_id", "task_id", "mandate_id", "status", "review_status", "review_id", "reviewed_by",
            "review_comment", "created_at", "applied_at", "proposal_json"), keys(all.path("items").get(0)));
        assertEquals(List.of("proposal_b"), texts(http.data("/proposals?task_id=task_b", 200).path("items"), "proposal_id"));
        assertEquals(List.of("proposal_a"), texts(http.data("/proposals?run_id=run_proposal_a", 200).path("items"), "proposal_id"));
        assertEquals(List.of("proposal_a"), texts(http.data("/proposals?review_status=PENDING", 200).path("items"), "proposal_id"));
        assertEquals(List.of("proposal_b"), texts(http.data("/proposals?review_status=APPROVED&status=DRAFT&work_id=" + WORK, 200).path("items"), "proposal_id"));
        JsonNode b = http.data("/proposals?task_id=task_b", 200).path("items").get(0);
        assertEquals("review_b", b.path("review_id").asText());
        assertEquals("Li Na", b.path("reviewed_by").asText());
        assertTrue(b.path("proposal_json").asText().contains("CREATE_ANNOTATION"), "proposal_json is the stored string");
        assertEquals(1, http.data("/proposals?limit=1", 200).path("items").size());
        assertTrue(http.data("/proposals?limit=1", 200).path("has_more").asBoolean());
        assertEquals("INVALID_FILTER", http.send(http.agentGet("/proposals?review_status=pending"), 400).path("data").path("code").asText());
    }

    @Test void proposalItemsEndpoint() throws Exception {
        fx.seedProposal("proposal_a");
        assertTrue(http.data("/proposals/proposal_a/items", 200).path("items").isEmpty());
        assertEquals("PROPOSAL_NOT_FOUND", http.send(http.agentGet("/proposals/proposal_none/items"), 404).path("data").path("code").asText());
    }

    // ------------------------------------------------------------------ 作品 / 来源

    @Test void worksListHasTheContractFields() throws Exception {
        JsonNode data = http.data("/works", 200);
        assertEquals(1, data.path("items").size());
        JsonNode w = data.path("items").get(0);
        assertEquals(set("work_id", "title", "status", "genre", "dynasty_id", "line_count", "version_count", "background_count", "annotation_count",
            "claim_count", "pending_source_count"), keys(w));
        assertEquals(WORK, w.path("work_id").asText());
        assertEquals("DRAFT", w.path("status").asText());
        assertEquals("dynasty-tang", w.path("dynasty_id").asText());
        assertEquals(8, w.path("line_count").asInt());
        assertEquals(1, w.path("version_count").asInt());
        assertEquals(4, w.path("background_count").asInt());
        assertEquals(2, w.path("annotation_count").asInt());
        assertEquals(9, w.path("claim_count").asInt());
        assertEquals(4, w.path("pending_source_count").asInt());
    }

    @Test void sourcesCarryCitationsWithLocatorState() throws Exception {
        JsonNode data = http.data("/sources", 200);
        assertEquals(4, data.path("items").size());
        JsonNode first = data.path("items").get(0);
        assertEquals(set("id", "title", "author", "edition", "url", "rights_note", "source_kind", "reliability", "verification_status",
            "verified_by", "verified_at", "citations"), keys(first));
        JsonNode nianpu = null;
        for (JsonNode s : data.path("items")) if ("source-dufu-nianpu-candidate".equals(s.path("id").asText())) nianpu = s;
        assertNotNull(nianpu);
        assertEquals(6, nianpu.path("citations").size());
        assertEquals(set("claim_id", "claim_value", "claim_kind", "claim_status", "locator", "evidence_excerpt", "locator_state"), keys(nianpu.path("citations").get(0)));
        for (JsonNode c : nianpu.path("citations")) assertEquals("PLACEHOLDER", c.path("locator_state").asText());

        fx.jdbc.update("UPDATE poetry_citation SET locator='卷一 第1页' WHERE claim_id='claim-bg-scene' AND source_id='source-dufu-nianpu-candidate'");
        fx.jdbc.update("UPDATE poetry_citation SET locator='' WHERE claim_id='claim-exp-757-time'");
        int set = 0, missing = 0;
        for (JsonNode s : http.data("/sources", 200).path("items"))
            if ("source-dufu-nianpu-candidate".equals(s.path("id").asText()))
                for (JsonNode c : s.path("citations")) { if ("SET".equals(c.path("locator_state").asText())) set++; if ("MISSING".equals(c.path("locator_state").asText())) missing++; }
        assertEquals(1, set);
        assertEquals(1, missing);
    }

    @Test void sourcesFilterByVerificationStatusAndPaginate() throws Exception {
        assertEquals(4, http.data("/sources?verification_status=PENDING", 200).path("items").size());
        assertTrue(http.data("/sources?verification_status=VERIFIED", 200).path("items").isEmpty());
        fx.jdbc.update("UPDATE poetry_source SET verification_status='REJECTED' WHERE id='source-anshi-candidate'");
        assertEquals(List.of("source-anshi-candidate"), texts(http.data("/sources?verification_status=REJECTED", 200).path("items"), "id"));
        JsonNode page = http.data("/sources?limit=3", 200);
        assertEquals(3, page.path("items").size());
        assertTrue(page.path("has_more").asBoolean());
        assertEquals("INVALID_FILTER", http.send(http.agentGet("/sources?verification_status=pending"), 400).path("data").path("code").asText());
        assertEquals("INVALID_PAGINATION", http.send(http.agentGet("/sources?limit=500"), 400).path("data").path("code").asText());
    }

    // ------------------------------------------------------------------ coverage

    @Test void coverageHasTheContractShape() throws Exception {
        JsonNode c = http.data("/works/" + WORK + "/coverage", 200);
        assertEquals(set("work_id", "totals", "claims_by_status", "claims_checkable", "sources_by_verification", "layers", "lines", "gap_codes", "publication"), keys(c));
        assertEquals(WORK, c.path("work_id").asText());
        JsonNode t = c.path("totals");
        assertEquals(set("lines", "versions", "backgrounds", "annotations", "claims", "sources", "citations"), keys(t));
        assertEquals(8, t.path("lines").asInt()); assertEquals(1, t.path("versions").asInt()); assertEquals(4, t.path("backgrounds").asInt());
        assertEquals(2, t.path("annotations").asInt()); assertEquals(9, t.path("claims").asInt()); assertEquals(4, t.path("sources").asInt());
        assertEquals(9, t.path("citations").asInt());
        assertEquals(9, c.path("claims_by_status").path("DRAFT").asInt());
        assertEquals(0, c.path("claims_by_status").path("PUBLISHED").asInt());
        assertEquals(0, c.path("claims_checkable").path("checkable").asInt());
        assertEquals(9, c.path("claims_checkable").path("total").asInt());
        assertEquals(4, c.path("sources_by_verification").path("PENDING").asInt());
        assertEquals(0, c.path("sources_by_verification").path("VERIFIED").asInt());
        assertEquals(0, c.path("sources_by_verification").path("REJECTED").asInt());
        assertEquals(List.of("SCENE", "CITY", "WORLD", "PERSON"), List.copyOf(keys(c.path("layers")).stream().sorted(java.util.Comparator.comparingInt(List.of("SCENE", "CITY", "WORLD", "PERSON")::indexOf)).toList()));
        for (String layer : List.of("SCENE", "CITY", "WORLD", "PERSON")) {
            assertEquals(set("count", "linked_lines"), keys(c.path("layers").path(layer)));
            assertEquals(1, c.path("layers").path(layer).path("count").asInt(), layer);
            assertEquals(2, c.path("layers").path(layer).path("linked_lines").asInt(), layer);
        }
        assertEquals(List.of("CLAIM_VERIFIED_CITATION_MISSING", "TEXT_SOURCE_NOT_VERIFIED", "ANNOTATION_COVERAGE_LOW"), texts(c.path("gap_codes"), ""),
            "gap_codes is a list of strings");
        assertEquals("DRAFT", c.path("publication").path("work_status").asText());
        assertEquals(0, c.path("publication").path("published_claims").asInt());
        assertEquals(106, c.path("publication").path("audit_checks").asInt());
        assertTrue(c.path("publication").path("audit_non_zero").isArray());
        assertTrue(c.path("publication").path("audit_non_zero").isEmpty());
    }

    @Test void coverageLinesAndCheckableReflectTheData() throws Exception {
        JsonNode lines = http.data("/works/" + WORK + "/coverage", 200).path("lines");
        assertEquals(8, lines.size());
        assertEquals(set("version_id", "line_seq", "content", "annotation_count", "background_count", "layers"), keys(lines.get(0)));
        JsonNode l1 = lines.get(0);
        assertEquals("text-chun-wang-draft", l1.path("version_id").asText());
        assertEquals(1, l1.path("line_seq").asInt());
        assertEquals("国破山河在，", l1.path("content").asText());
        assertEquals(1, l1.path("annotation_count").asInt());
        assertEquals(2, l1.path("background_count").asInt());
        assertEquals(List.of("SCENE", "CITY"), texts(l1.path("layers"), ""));
        JsonNode l3 = lines.get(2);
        assertEquals(0, l3.path("annotation_count").asInt()); assertEquals(0, l3.path("background_count").asInt()); assertTrue(l3.path("layers").isEmpty());
        assertEquals(List.of("WORLD"), texts(lines.get(4).path("layers"), ""));
        assertEquals(1, lines.get(4).path("annotation_count").asInt());

        fx.jdbc.update("UPDATE poetry_citation SET locator='卷一 第1页' WHERE claim_id='claim-chun-wang-author'");
        assertEquals(1, http.data("/works/" + WORK + "/coverage", 200).path("claims_checkable").path("checkable").asInt());
    }

    @Test void coverageSurfacesAuditFailuresWithoutRunningTheAuditTwice() throws Exception {
        fx.audit.offer(new AuditRunner.Result(106, List.of("C9_x=1")));
        JsonNode c = http.data("/works/" + WORK + "/coverage", 200);
        assertTrue(texts(c.path("gap_codes"), "").contains("INTEGRITY_AUDIT_NONZERO"));
        assertEquals(List.of("C9_x=1"), texts(c.path("publication").path("audit_non_zero"), ""));
    }

    @Test void coverageAndStudioViewRejectUnknownAndMalformedWorkIds() throws Exception {
        for (String route : List.of("coverage", "studio-view")) {
            assertEquals("WORK_NOT_FOUND", http.send(http.agentGet("/works/work-nope/" + route), 404).path("data").path("code").asText());
            assertEquals("INVALID_ID", http.send(http.agentGet("/works/x/" + route), 400).path("data").path("code").asText());
            assertEquals("WORK_NOT_FOUND", http.send(http.agentGet("/works/person-du-fu/" + route), 404).path("data").path("code").asText(), "only WORK entities");
        }
    }

    // ------------------------------------------------------------------ studio-view

    @Test void studioViewHasTheContractShape() throws Exception {
        JsonNode v = http.data("/works/" + WORK + "/studio-view", 200);
        assertEquals(set("work", "work_info", "versions", "lines", "claims", "citations", "backgrounds", "annotations", "sources", "background_lines",
            "claim_status_by_id", "content_status_by_id", "version_status_by_id", "source_verification_by_id", "coverage_rows", "gap_report"), keys(v));
        assertEquals(WORK, v.path("work").path("id").asText());
        assertEquals("DRAFT", v.path("work").path("status").asText());
        assertEquals(set("id", "entity_type", "slug", "title", "summary", "start_year", "end_year", "time_precision", "status", "revision", "reviewed_by"), keys(v.path("work")));
        assertEquals(set("id", "genre", "dynasty_id", "creation_place_id"), keys(v.path("work_info")));
        assertEquals(1, v.path("versions").size());
        assertEquals(set("id", "work_id", "version_code", "label", "script", "source_id", "source_locator", "status"), keys(v.path("versions").get(0)));
        assertEquals(8, v.path("lines").size());
        assertEquals(set("version_id", "line_seq", "content", "pinyin"), keys(v.path("lines").get(0)));
        assertEquals(9, v.path("claims").size());
        assertEquals(set("id", "subject_id", "property_key", "value_text", "claim_kind", "certainty", "status"), keys(v.path("claims").get(0)));
        assertEquals(9, v.path("citations").size());
        assertEquals(set("claim_id", "source_id", "locator", "evidence_excerpt", "verification_status"), keys(v.path("citations").get(0)));
        assertEquals(4, v.path("backgrounds").size());
        assertEquals(set("id", "work_id", "layer", "audience", "body_text", "claim_id"), keys(v.path("backgrounds").get(0)));
        assertEquals(2, v.path("annotations").size());
        assertEquals(set("id", "version_id", "line_seq", "annotation_kind", "audience", "content", "claim_id"), keys(v.path("annotations").get(0)));
        assertEquals(4, v.path("sources").size());
        assertEquals(set("id", "title", "author", "edition", "url", "rights_note", "source_kind", "reliability", "verification_status"), keys(v.path("sources").get(0)));
        assertEquals(8, v.path("background_lines").size());
        assertEquals(set("background_id", "version_id", "line_seq"), keys(v.path("background_lines").get(0)));
    }

    @Test void studioViewStatusMapsAndGapReport() throws Exception {
        JsonNode v = http.data("/works/" + WORK + "/studio-view", 200);
        assertEquals(9, v.path("claim_status_by_id").size());
        assertEquals("DRAFT", v.path("claim_status_by_id").path("claim-chun-wang-author").asText());
        JsonNode content = v.path("content_status_by_id");
        assertEquals(5, content.size(), "the work plus its four backgrounds");
        assertEquals("DRAFT", content.path(WORK).asText());
        assertEquals("DRAFT", content.path("bg-chun-wang-scene").asText());
        assertEquals("DRAFT", v.path("version_status_by_id").path("text-chun-wang-draft").asText());
        assertEquals(4, v.path("source_verification_by_id").size());
        assertEquals("PENDING", v.path("source_verification_by_id").path("source-anshi-candidate").asText());
        assertEquals(1, v.path("coverage_rows").size(), "only WORK coverage rows");
        assertEquals(set("id", "entity_type", "from_year", "to_year", "coverage_kind", "status", "note"), keys(v.path("coverage_rows").get(0)));
        JsonNode gap = v.path("gap_report");
        assertEquals(set("work_id", "gaps", "audit_checks", "audit_non_zero"), keys(gap));
        assertTrue(gap.path("gaps").size() >= 3);
        assertEquals(set("code", "severity", "message", "target_ref"), keys(gap.path("gaps").get(0)));
        assertEquals(106, gap.path("audit_checks").asInt());
    }

    @Test void studioViewClaimsAreASupersetOfTheAgentSnapshot() throws Exception {
        JsonNode v = http.data("/works/" + WORK + "/studio-view", 200);
        Set<String> viewClaims = new TreeSet<>(texts(v.path("claims"), "id"));
        Set<String> viewSources = new TreeSet<>(texts(v.path("sources"), "id"));
        for (Object c : fx.agent.snapshot(WORK).claims()) {
            String id = ((com.timeline.poetry.api.PoetryDraftModels.DraftClaim) c).id();
            assertTrue(viewClaims.contains(id), id);
        }
        for (Object s : fx.agent.snapshot(WORK).sources())
            assertTrue(viewSources.contains(((com.timeline.poetry.api.PoetryDraftModels.DraftSource) s).id()));
    }

    // ------------------------------------------------------------------ 与既有路由共存

    @Test void newRoutesDoNotShadowTheExistingOrchestrationRoutes() throws Exception {
        fx.seedTask("task_a", WORK, "GAP_ANALYSIS", "COMPLETED", "2026-11-01 10:00:00");
        JsonNode task = http.send(http.agentGet("/tasks/task_a"), 200);
        assertEquals("OK", task.path("status").asText());
        assertEquals("task_a", task.path("data").path("task_id").asText());
        assertTrue(task.has("audit_refs"));

        fx.seedTask("task_b", WORK, "ANNOTATION_DRAFT", "RUNNING", "2026-11-02 10:00:00");
        fx.seedRun("run_proposal_b", "task_b");
        fx.seedProposal("proposal_b");
        JsonNode one = http.send(http.agentGet("/proposals/proposal_b"), 200);
        assertEquals("proposal_b", one.path("data").path("proposal_id").asText());
        assertEquals("task_b", one.path("data").path("task_id").asText());
        assertEquals(1, http.data("/proposals", 200).path("items").size());
    }
}
