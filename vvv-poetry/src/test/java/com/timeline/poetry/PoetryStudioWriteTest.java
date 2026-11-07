package com.timeline.poetry;

import com.fasterxml.jackson.databind.JsonNode;
import com.timeline.poetry.service.AuditRunner;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import java.util.ArrayList;
import java.util.List;
import static com.timeline.poetry.PoetryStudioHttp.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

/** 写入口：令牌隔离、署名/角色、locator、VERIFY/REJECT、逐项评审。H2 + 真实迁移文件，不跑在宿主里。 */
class PoetryStudioWriteTest {
    private static final String CLAIM = "claim-bg-city";
    private static final String SOURCE = "source-anshi-candidate";
    private static final String LOCATOR_PATH = "/citations/" + CLAIM + "/" + SOURCE + "/locator";
    private static final String NIANPU = "source-dufu-nianpu-candidate";

    PoetryStudioFixture fx;
    PoetryStudioHttp http;

    @BeforeEach void setUp() throws Exception { fx = new PoetryStudioFixture(); http = new PoetryStudioHttp(fx); }

    private static java.util.Map<String, Object> locatorBody(String locator, String reviewer, String role) {
        java.util.Map<String, Object> m = map("reviewer", reviewer, "reviewer_role", role);
        if (locator != null) m.put("locator", locator);
        return m;
    }
    private int count(String sql, Object... args) { return fx.jdbc.queryForObject(sql, Integer.class, args); }
    private String locatorInDb() { return fx.jdbc.queryForObject("SELECT locator FROM poetry_citation WHERE claim_id=? AND source_id=?", String.class, CLAIM, SOURCE); }

    // ------------------------------------------------------------------ 令牌隔离

    @Test void agentTokenCannotCallStudioWrites() throws Exception {
        MockHttpServletRequestBuilder withAgentTokenInStudioHeader = put(STUDIO + LOCATOR_PATH).header(STUDIO_HEADER, PoetryStudioFixture.AGENT_TOKEN)
            .contentType("application/json").content("{}");
        assertEquals("UNAUTHORIZED", http.send(withAgentTokenInStudioHeader, 401).path("status").asText());
        MockHttpServletRequestBuilder agentHeaderOnly = put(STUDIO + LOCATOR_PATH).header(AGENT_HEADER, PoetryStudioFixture.AGENT_TOKEN)
            .contentType("application/json").content("{}");
        http.send(agentHeaderOnly, 401);
        http.send(post(STUDIO + "/sources/" + NIANPU + "/verification").header(AGENT_HEADER, PoetryStudioFixture.AGENT_TOKEN)
            .contentType("application/json").content("{}"), 401);
        http.send(put(STUDIO + "/proposals/proposal_x/items").header(AGENT_HEADER, PoetryStudioFixture.AGENT_TOKEN)
            .contentType("application/json").content("{}"), 401);
        assertEquals(0, count("SELECT COUNT(*) FROM poetry_studio_check_log"));
    }

    @Test void missingOrWrongTokenIs401EvenWithABrokenBody() throws Exception {
        http.send(put(STUDIO + LOCATOR_PATH).contentType("application/json").content("not json"), 401);
        http.send(put(STUDIO + LOCATOR_PATH).header(STUDIO_HEADER, "wrong").contentType("application/json").content("not json"), 401);
        http.send(put(STUDIO + LOCATOR_PATH).header(STUDIO_HEADER, "").contentType("application/json").content("{}"), 401);
    }

    @Test void unconfiguredStudioTokenIs503() throws Exception {
        PoetryStudioFixture off = new PoetryStudioFixture("", PoetryStudioFixture.AGENT_TOKEN);
        PoetryStudioHttp offHttp = new PoetryStudioHttp(off);
        JsonNode r = offHttp.send(put(STUDIO + LOCATOR_PATH).header(STUDIO_HEADER, "anything").contentType("application/json").content("{}"), 503);
        assertEquals("UNAVAILABLE", r.path("status").asText());
        assertEquals("STUDIO_WRITE_DISABLED", r.path("data").path("code").asText());
    }

    @Test void studioTokenEqualToAgentTokenIsTreatedAsUnconfigured() throws Exception {
        PoetryStudioFixture same = new PoetryStudioFixture(PoetryStudioFixture.AGENT_TOKEN, PoetryStudioFixture.AGENT_TOKEN);
        new PoetryStudioHttp(same).send(put(STUDIO + LOCATOR_PATH).header(STUDIO_HEADER, PoetryStudioFixture.AGENT_TOKEN)
            .contentType("application/json").content("{}"), 503);
    }

    @Test void studioTokenCannotCallAgentReadRoutes() throws Exception {
        http.send(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get(ORCH + "/tasks").header(AGENT_HEADER, PoetryStudioFixture.STUDIO_TOKEN), 403);
        http.send(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get(ORCH + "/tasks"), 403);
        http.send(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get(ORCH + "/works/work-chun-wang/studio-view").header(STUDIO_HEADER, PoetryStudioFixture.STUDIO_TOKEN), 403);
    }

    // ------------------------------------------------------------------ 署名与角色

    @Test void machineSignaturesAreRejectedAndPinyinNamesAccepted() throws Exception {
        for (String bad : List.of("AI Reviewer", "deerflow-agent", "mcp", "MyBot", "system", "x")) {
            JsonNode r = http.send(http.studioPut(LOCATOR_PATH, locatorBody("卷一 第1页", bad, "HISTORICAL_REVIEWER")), 400);
            assertEquals("INVALID_REVIEWER", r.path("data").path("code").asText(), bad);
        }
        assertTrue(locatorInDb().startsWith("待"), "no write happened");
        http.send(http.studioPut(LOCATOR_PATH, locatorBody("卷一 第1页", "Wang Ai", "HISTORICAL_REVIEWER")), 200);
    }

    @Test void rolesAreEnforcedForLocatorAndVerification() throws Exception {
        JsonNode editor = http.send(http.studioPut(LOCATOR_PATH, locatorBody("卷一 第1页", "Li Na", "CONTENT_EDITOR")), 403);
        assertEquals("ROLE_NOT_ALLOWED", editor.path("data").path("code").asText());
        assertEquals("INVALID_ROLE", http.send(http.studioPut(LOCATOR_PATH, locatorBody("卷一 第1页", "Li Na", "RELEASE_MANAGER")), 400).path("data").path("code").asText());
        assertEquals("INVALID_ROLE", http.send(http.studioPut(LOCATOR_PATH, locatorBody("卷一 第1页", "Li Na", null)), 400).path("data").path("code").asText());
        http.send(http.studioPost("/sources/" + NIANPU + "/verification", map("decision", "VERIFY", "reviewer", "Li Na", "reviewer_role", "CONTENT_EDITOR")), 403);
        http.send(http.studioPost("/sources/" + NIANPU + "/verification", map("decision", "REJECT", "reviewer", "Li Na", "reviewer_role", "CONTENT_EDITOR")), 403);
        assertTrue(locatorInDb().startsWith("待"));
        assertEquals("PENDING", fx.jdbc.queryForObject("SELECT verification_status FROM poetry_source WHERE id=?", String.class, NIANPU));
        assertEquals(0, count("SELECT COUNT(*) FROM poetry_studio_check_log"));
    }

    // ------------------------------------------------------------------ locator

    @Test void locatorIsUpdatedAuditedAndTheSourceStatusIsUntouched() throws Exception {
        JsonNode r = http.send(http.studioPut(LOCATOR_PATH, map("locator", "  《资治通鉴》卷二百一十八  ", "evidence_excerpt", "摘录原文", "reviewer", "Zhang Wei",
            "reviewer_role", "HISTORICAL_REVIEWER", "note", "对照影印本")), 200);
        assertEquals("OK", r.path("status").asText());
        assertEquals("《资治通鉴》卷二百一十八", r.path("data").path("locator").asText());
        assertEquals("SET", r.path("data").path("locator_state").asText());
        assertEquals("PENDING", r.path("data").path("source_verification_status").asText());
        assertTrue(r.path("audit_refs").get(0).asText().startsWith("studio-check-log:"));
        assertEquals("《资治通鉴》卷二百一十八", locatorInDb());
        assertEquals("PENDING", fx.jdbc.queryForObject("SELECT verification_status FROM poetry_source WHERE id=?", String.class, SOURCE));
        var log = fx.jdbc.queryForList("SELECT * FROM poetry_studio_check_log");
        assertEquals(1, log.size());
        assertEquals("SET_LOCATOR", log.get(0).get("action"));
        assertEquals("Zhang Wei", log.get(0).get("reviewer"));
        assertEquals("HISTORICAL_REVIEWER", log.get(0).get("reviewer_role"));
        assertEquals(SOURCE, log.get(0).get("source_id"));
        assertEquals(CLAIM, log.get(0).get("claim_id"));
        assertTrue(String.valueOf(log.get(0).get("note")).contains("previous_locator=待人工核对"), "the replaced placeholder is kept in the audit note");
    }

    @Test void evidenceExcerptIsKeptWhenNotSentAgain() throws Exception {
        http.send(http.studioPut(LOCATOR_PATH, map("locator", "卷一 第1页", "evidence_excerpt", "原文摘录", "reviewer", "Zhang Wei", "reviewer_role", ROLE())), 200);
        http.send(http.studioPut(LOCATOR_PATH, map("locator", "卷一 第2页", "reviewer", "Zhang Wei", "reviewer_role", ROLE())), 200);
        assertEquals("原文摘录", fx.jdbc.queryForObject("SELECT evidence_excerpt FROM poetry_citation WHERE claim_id=? AND source_id=?", String.class, CLAIM, SOURCE));
        assertEquals("卷一 第2页", locatorInDb());
    }

    @Test void emptyPlaceholderAndOverlongLocatorsAreRejected() throws Exception {
        List<String> bad = new ArrayList<>(List.of("", "   ", "待核查", "待人工核对", "未核对", "TBD", "tbd", "DEMO", "演练", "-"));
        bad.add("卷".repeat(301));
        for (String locator : bad) {
            JsonNode r = http.send(http.studioPut(LOCATOR_PATH, locatorBody(locator, "Zhang Wei", ROLE())), 400);
            assertEquals("INVALID_LOCATOR", r.path("data").path("code").asText(), "[" + locator + "]");
        }
        assertEquals("INVALID_LOCATOR", http.send(http.studioPut(LOCATOR_PATH, locatorBody(null, "Zhang Wei", ROLE())), 400).path("data").path("code").asText());
        assertTrue(locatorInDb().startsWith("待"), "nothing was written");
        assertEquals(0, count("SELECT COUNT(*) FROM poetry_studio_check_log"));
        http.send(http.studioPut(LOCATOR_PATH, locatorBody("卷".repeat(300), "Zhang Wei", ROLE())), 200);
    }

    @Test void onlyAnExistingCitationCanBeEdited() throws Exception {
        JsonNode r = http.send(http.studioPut("/citations/" + CLAIM + "/source-chun-wang-candidate/locator", locatorBody("卷一 第1页", "Zhang Wei", ROLE())), 404);
        assertEquals("CITATION_NOT_FOUND", r.path("data").path("code").asText());
        assertEquals(0, count("SELECT COUNT(*) FROM poetry_citation WHERE claim_id=? AND source_id=?", CLAIM, "source-chun-wang-candidate"));
        assertEquals("INVALID_ID", http.send(http.studioPut("/citations/x/" + SOURCE + "/locator", locatorBody("卷一 第1页", "Zhang Wei", ROLE())), 400).path("data").path("code").asText());
    }

    @Test void unknownFieldsWrongCasingAndBrokenJsonAreRejectedWithAReadableCode() throws Exception {
        java.util.Map<String, Object> camel = map("locator", "卷一 第1页", "reviewer", "Zhang Wei", "reviewerRole", ROLE());
        assertEquals("BODY_INVALID", http.send(http.studioPut(LOCATOR_PATH, camel), 400).path("data").path("code").asText());
        assertEquals("BODY_INVALID", http.send(http.studioPut(LOCATOR_PATH, map("locator", "卷一 第1页", "reviewer", "Zhang Wei", "reviewer_role", ROLE(), "verified", true)), 400).path("data").path("code").asText());
        MockHttpServletRequestBuilder broken = put(STUDIO + LOCATOR_PATH).header(STUDIO_HEADER, PoetryStudioFixture.STUDIO_TOKEN).contentType("application/json").content("{not json");
        assertEquals("BODY_INVALID", http.send(broken, 400).path("data").path("code").asText());
        MockHttpServletRequestBuilder empty = put(STUDIO + LOCATOR_PATH).header(STUDIO_HEADER, PoetryStudioFixture.STUDIO_TOKEN).contentType("application/json").content("");
        assertEquals("BODY_REQUIRED", http.send(empty, 400).path("data").path("code").asText());
    }

    private static String ROLE() { return PoetryStudioFixture.ROLE; }

    // ------------------------------------------------------------------ 来源核验

    private java.util.Map<String, Object> verify(String decision) { return map("decision", decision, "reviewer", "Zhang Wei", "reviewer_role", ROLE()); }
    private void fillAllLocators(String sourceId) { fx.jdbc.update("UPDATE poetry_citation SET locator='卷一 第1页' WHERE source_id=?", sourceId); }

    @Test void verifyWithMissingLocatorsIs409AndListsTheClaims() throws Exception {
        int citations = count("SELECT COUNT(*) FROM poetry_citation WHERE source_id=?", NIANPU);
        assertTrue(citations > 1);
        JsonNode r = http.send(http.studioPost("/sources/" + NIANPU + "/verification", verify("VERIFY")), 409);
        assertEquals("CONFLICT", r.path("status").asText());
        assertEquals("LOCATOR_MISSING", r.path("data").path("code").asText());
        JsonNode missing = r.path("data").path("details").path("missing");
        assertEquals(citations, missing.size());
        assertEquals("PLACEHOLDER", missing.get(0).path("locator_state").asText());
        assertTrue(missing.get(0).has("claim_id"));
        assertEquals("PENDING", fx.jdbc.queryForObject("SELECT verification_status FROM poetry_source WHERE id=?", String.class, NIANPU));

        // 填完其中一部分仍然是 409，且只列出还缺的
        fx.jdbc.update("UPDATE poetry_citation SET locator='卷一 第1页' WHERE source_id=? AND claim_id=?", NIANPU, "claim-bg-scene");
        JsonNode again = http.send(http.studioPost("/sources/" + NIANPU + "/verification", verify("VERIFY")), 409);
        assertEquals(citations - 1, again.path("data").path("details").path("missing").size());
    }

    @Test void verifyReusesPublishAndWritesReviewLogAndCheckLog() throws Exception {
        fillAllLocators(NIANPU);
        JsonNode r = http.send(http.studioPost("/sources/" + NIANPU + "/verification", verify("VERIFY")), 200);
        assertEquals("VERIFIED", r.path("data").path("verification_status").asText());
        assertTrue(r.path("data").path("changed").asBoolean());
        assertEquals("Zhang Wei", fx.jdbc.queryForObject("SELECT verified_by FROM poetry_source WHERE id=?", String.class, NIANPU));
        assertEquals(1, count("SELECT COUNT(*) FROM poetry_review_log WHERE subject_table='poetry_source' AND subject_id=? AND decision='PUBLISHED'", NIANPU));
        assertEquals(1, count("SELECT COUNT(*) FROM poetry_studio_check_log WHERE action='VERIFY_SOURCE' AND source_id=? AND decision='VERIFY'", NIANPU));

        JsonNode second = http.send(http.studioPost("/sources/" + NIANPU + "/verification", verify("VERIFY")), 200);
        assertFalse(second.path("data").path("changed").asBoolean(), "repeat VERIFY is a no-op");
        assertEquals(1, count("SELECT COUNT(*) FROM poetry_studio_check_log WHERE action='VERIFY_SOURCE'"));
        assertEquals(1, count("SELECT COUNT(*) FROM poetry_review_log WHERE subject_id=? AND decision='PUBLISHED'", NIANPU));
    }

    @Test void publicationGateStillBlocksAnUngradedSourceEvenWithLocators() throws Exception {
        String ungraded = "source-chun-wang-candidate";   // V002 来源：没有 source_kind / reliability
        fillAllLocators(ungraded);
        JsonNode r = http.send(http.studioPost("/sources/" + ungraded + "/verification", verify("VERIFY")), 409);
        assertEquals("PUBLISH_BLOCKED", r.path("data").path("code").asText());
        assertTrue(r.path("data").path("details").path("blocking").size() > 0);
        assertEquals("PENDING", fx.jdbc.queryForObject("SELECT verification_status FROM poetry_source WHERE id=?", String.class, ungraded));
        assertEquals(0, count("SELECT COUNT(*) FROM poetry_studio_check_log"));
    }

    @Test void auditFailuresBlockOrRollBackTheVerification() throws Exception {
        fillAllLocators(NIANPU);
        fx.audit.offer(new AuditRunner.Result(106, List.of("C5_x=1")));          // publish 前置审计不干净
        JsonNode blocked = http.send(http.studioPost("/sources/" + NIANPU + "/verification", verify("VERIFY")), 409);
        assertEquals("PUBLISH_BLOCKED", blocked.path("data").path("code").asText());
        assertTrue(blocked.path("data").path("details").path("blocking").toString().contains("C5_x=1"));
        assertEquals("PENDING", fx.jdbc.queryForObject("SELECT verification_status FROM poetry_source WHERE id=?", String.class, NIANPU));

        fx.audit.offer(new AuditRunner.Result(106, List.of()));                   // 前置干净
        fx.audit.offer(new AuditRunner.Result(106, List.of("C5_y=2")));           // 发布后不干净 -> publish 抛 IllegalStateException
        JsonNode rolled = http.send(http.studioPost("/sources/" + NIANPU + "/verification", verify("VERIFY")), 409);
        assertEquals("AUDIT_ROLLBACK", rolled.path("data").path("code").asText());
        // 注意：单测里没有事务管理器，真正的回滚由宿主里的 @Transactional 完成；这里只验证响应码与错误码。
        assertEquals(0, count("SELECT COUNT(*) FROM poetry_studio_check_log WHERE action='VERIFY_SOURCE'"));
    }

    @Test void rejectUsesRetractAndIsIdempotent() throws Exception {
        JsonNode r = http.send(http.studioPost("/sources/" + NIANPU + "/verification", map("decision", "REJECT", "reviewer", "Zhang Wei", "reviewer_role", "PLATFORM_ADMIN", "note", "底本不可靠")), 200);
        assertEquals("REJECTED", r.path("data").path("verification_status").asText());
        assertEquals("REJECTED", fx.jdbc.queryForObject("SELECT verification_status FROM poetry_source WHERE id=?", String.class, NIANPU));
        assertEquals(1, count("SELECT COUNT(*) FROM poetry_review_log WHERE subject_id=? AND decision='RETRACTED'", NIANPU));
        assertEquals(1, count("SELECT COUNT(*) FROM poetry_studio_check_log WHERE action='REJECT_SOURCE' AND decision='REJECT' AND reviewer_role='PLATFORM_ADMIN'"));
        JsonNode again = http.send(http.studioPost("/sources/" + NIANPU + "/verification", verify("REJECT")), 200);
        assertFalse(again.path("data").path("changed").asBoolean());
        assertEquals(1, count("SELECT COUNT(*) FROM poetry_studio_check_log WHERE action='REJECT_SOURCE'"));
    }

    @Test void invalidDecisionAndUnknownSource() throws Exception {
        assertEquals("INVALID_DECISION", http.send(http.studioPost("/sources/" + NIANPU + "/verification", verify("PUBLISH")), 400).path("data").path("code").asText());
        assertEquals("INVALID_DECISION", http.send(http.studioPost("/sources/" + NIANPU + "/verification", map("reviewer", "Zhang Wei", "reviewer_role", ROLE())), 400).path("data").path("code").asText());
        assertEquals("SOURCE_NOT_FOUND", http.send(http.studioPost("/sources/source-nope/verification", verify("VERIFY")), 404).path("data").path("code").asText());
        assertEquals("INVALID_REVIEWER", http.send(http.studioPost("/sources/" + NIANPU + "/verification", map("decision", "VERIFY", "reviewer", "AI Reviewer", "reviewer_role", ROLE())), 400).path("data").path("code").asText());
    }

    // ------------------------------------------------------------------ 逐项评审

    private java.util.Map<String, Object> items(String reviewer, String role, Object... decisions) {
        List<Object> list = new ArrayList<>();
        for (Object d : decisions) list.add(d);
        return map("decisions", list, "reviewer", reviewer, "reviewer_role", role);
    }
    private java.util.Map<String, Object> d(Object index, String decision) { return map("item_index", index, "decision", decision); }

    @Test void itemDecisionsAreRecordedOverwrittenAndAudited() throws Exception {
        fx.seedProposal("proposal_t1");
        JsonNode r = http.send(http.studioPut("/proposals/proposal_t1/items", items("Li Na", "CONTENT_EDITOR", d(0, "APPROVE"), d(1, "REJECT"), d(2, "APPROVE"))), 200);
        assertEquals(2, r.path("data").path("executable_count").asInt());
        assertEquals(3, r.path("data").path("recorded").asInt());
        JsonNode listed = http.data("/proposals/proposal_t1/items", 200).path("items");
        assertEquals(3, listed.size());
        assertEquals(List.of("comment", "created_at", "decision", "item_index", "reviewer"), List.copyOf(keys(listed.get(0))));
        assertEquals("REJECT", listed.get(1).path("decision").asText());

        http.send(http.studioPut("/proposals/proposal_t1/items", items("Li Na", "HISTORICAL_REVIEWER", map("item_index", 1, "decision", "APPROVE", "comment", "改主意了"))), 200);
        JsonNode after = http.data("/proposals/proposal_t1/items", 200).path("items");
        assertEquals(3, after.size(), "overwrite, not append");
        assertEquals("APPROVE", after.get(1).path("decision").asText());
        assertEquals("改主意了", after.get(1).path("comment").asText());
        assertEquals(2, count("SELECT COUNT(*) FROM poetry_studio_check_log WHERE action='ITEM_DECISIONS' AND proposal_id='proposal_t1'"));
    }

    @Test void invalidItemDecisionsWriteNothing() throws Exception {
        fx.seedProposal("proposal_t2");
        List<Object[]> cases = List.of(
            new Object[]{items("Li Na", "CONTENT_EDITOR", d(3, "APPROVE")), "INVALID_ITEM_INDEX"},
            new Object[]{items("Li Na", "CONTENT_EDITOR", d(-1, "APPROVE")), "INVALID_ITEM_INDEX"},
            new Object[]{items("Li Na", "CONTENT_EDITOR", d(1.5, "APPROVE")), "INVALID_ITEM_INDEX"},
            new Object[]{items("Li Na", "CONTENT_EDITOR", map("decision", "APPROVE")), "INVALID_ITEM_INDEX"},
            new Object[]{items("Li Na", "CONTENT_EDITOR", d(0, "APPROVE"), d(0, "REJECT")), "DUPLICATE_ITEM_INDEX"},
            new Object[]{items("Li Na", "CONTENT_EDITOR", d(0, "MAYBE")), "INVALID_DECISION"},
            new Object[]{items("Li Na", "CONTENT_EDITOR"), "DECISIONS_REQUIRED"},
            new Object[]{items("Li Na", "RELEASE_MANAGER", d(0, "APPROVE")), "INVALID_ROLE"},
            new Object[]{items("agent-1", "CONTENT_EDITOR", d(0, "APPROVE")), "INVALID_REVIEWER"});
        for (Object[] c : cases) {
            @SuppressWarnings("unchecked") java.util.Map<String, Object> body = (java.util.Map<String, Object>) c[0];
            assertEquals(c[1], http.send(http.studioPut("/proposals/proposal_t2/items", body), 400).path("data").path("code").asText(), String.valueOf(c[1]));
        }
        List<Object> many = new ArrayList<>();
        for (int i = 0; i < 51; i++) many.add(d(i % 3, "APPROVE"));
        assertEquals("TOO_MANY_DECISIONS", http.send(http.studioPut("/proposals/proposal_t2/items", items("Li Na", "CONTENT_EDITOR", many.toArray())), 400).path("data").path("code").asText());
        assertEquals(0, count("SELECT COUNT(*) FROM poetry_agent_proposal_item"));
        assertEquals(0, count("SELECT COUNT(*) FROM poetry_studio_check_log"));
    }

    @Test void itemDecisionsOnlyWhilePendingAndOnlyForKnownProposals() throws Exception {
        fx.seedProposal("proposal_t3");
        fx.approveProposal("proposal_t3", "review_t3");
        JsonNode r = http.send(http.studioPut("/proposals/proposal_t3/items", items("Li Na", "CONTENT_EDITOR", d(0, "APPROVE"))), 409);
        assertEquals("PROPOSAL_NOT_PENDING", r.path("data").path("code").asText());
        assertEquals(0, count("SELECT COUNT(*) FROM poetry_agent_proposal_item"));
        assertEquals("PROPOSAL_NOT_FOUND", http.send(http.studioPut("/proposals/proposal_none/items", items("Li Na", "CONTENT_EDITOR", d(0, "APPROVE"))), 404).path("data").path("code").asText());
    }
}
