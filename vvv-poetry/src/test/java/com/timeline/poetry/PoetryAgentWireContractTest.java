package com.timeline.poetry;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.timeline.poetry.api.PoetryAgentModels.AgentResponse;
import com.timeline.poetry.api.PoetryAgentModels.CompileRequest;
import com.timeline.poetry.api.PoetryAgentModels.Gap;
import com.timeline.poetry.api.PoetryAgentModels.GapReport;
import com.timeline.poetry.api.PoetryAgentModels.ProposalApply;
import com.timeline.poetry.api.PoetryAgentModels.ProposalCreate;
import com.timeline.poetry.api.PoetryAgentModels.ProposalReview;
import com.timeline.poetry.api.PoetryAgentModels.Snapshot;
import com.timeline.poetry.api.PoetryAgentOrchestrationModels.EventAppend;
import com.timeline.poetry.api.PoetryAgentOrchestrationModels.RunCreate;
import com.timeline.poetry.api.PoetryAgentOrchestrationModels.RunStateChange;
import com.timeline.poetry.api.PoetryAgentOrchestrationModels.RuntimeAdmission;
import com.timeline.poetry.api.PoetryAgentOrchestrationModels.TaskCreate;
import com.timeline.poetry.api.PoetryAgentWire;
import com.timeline.poetry.api.PoetryModels.WorkInfo;
import java.util.List;
import java.util.Map;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;

/**
 * The Agent API speaks snake_case no matter how the host application configures Jackson.
 *
 * <p>The host's global naming strategy cannot be seen from this repository, so these tests run every
 * assertion under three mapper configurations (default, SNAKE_CASE, LOWER_CAMEL_CASE) and require the
 * same result. MCP, the BFF and agent-worker all send and expect snake_case.
 */
class PoetryAgentWireContractTest {

    static Stream<ObjectMapper> hostMappers() {
        return Stream.of(
            new ObjectMapper(),
            new ObjectMapper().setPropertyNamingStrategy(PropertyNamingStrategies.SNAKE_CASE),
            new ObjectMapper().setPropertyNamingStrategy(PropertyNamingStrategies.LOWER_CAMEL_CASE));
    }

    // ------------------------------------------------------------------ requests (MCP → Java)

    @ParameterizedTest @MethodSource("hostMappers")
    void taskCreateReadsSnakeCaseKeys(ObjectMapper host) throws Exception {
        TaskCreate t = host.readValue("""
            {"task_id":"task_1","work_id":"work-chun-wang","title":"缺口","task_type":"GAP_ANALYSIS",
             "requested_by":"li","requested_role":"CONTENT_EDITOR","instructions":"看","requested_profile":"authoring"}""",
            TaskCreate.class);
        assertEquals("task_1", t.taskId());
        assertEquals("work-chun-wang", t.workId());
        assertEquals("GAP_ANALYSIS", t.taskType());
        assertEquals("li", t.requestedBy());
        assertEquals("CONTENT_EDITOR", t.requestedRole());
        assertEquals("authoring", t.requestedProfile());
    }

    @ParameterizedTest @MethodSource("hostMappers")
    void camelCaseIsStillAcceptedAsAnAlias(ObjectMapper host) throws Exception {
        TaskCreate t = host.readValue("""
            {"taskId":"task_2","workId":"w","title":"t","taskType":"GAP_ANALYSIS","requestedBy":"x",
             "requestedRole":"CONTENT_EDITOR","instructions":"i","requestedProfile":"authoring"}""", TaskCreate.class);
        assertEquals("task_2", t.taskId());
        assertEquals("GAP_ANALYSIS", t.taskType());
    }

    @ParameterizedTest @MethodSource("hostMappers")
    void runAndAdmissionAndEventRecordsReadSnakeCaseKeys(ObjectMapper host) throws Exception {
        RunCreate run = host.readValue("""
            {"run_id":"run_1","mandate_id":"mandate_1","runtime":"STUB","profile_name":"authoring",
             "profile_fingerprint":"%s","profile_manifest":{"k":1}}""".formatted("a".repeat(64)), RunCreate.class);
        assertEquals("run_1", run.runId());
        assertEquals("mandate_1", run.mandateId());
        assertEquals("authoring", run.profileName());
        assertTrue(run.profileManifest().isObject());

        RuntimeAdmission a = host.readValue(
            "{\"status\":\"RUNNING\",\"runtime_thread_id\":\"th\",\"runtime_run_id\":\"rr\",\"reason\":\"r\"}",
            RuntimeAdmission.class);
        assertEquals("th", a.runtimeThreadId());
        assertEquals("rr", a.runtimeRunId());

        EventAppend e = host.readValue("{\"event_type\":\"STEP\",\"payload\":{\"n\":1}}", EventAppend.class);
        assertEquals("STEP", e.eventType());
        assertEquals(1, e.payload().get("n").asInt());

        RunStateChange s = host.readValue("{\"status\":\"FAILED\",\"reason\":\"x\"}", RunStateChange.class);
        assertEquals("FAILED", s.status());
    }

    @ParameterizedTest @MethodSource("hostMappers")
    void proposalRecordsReadSnakeCaseKeys(ObjectMapper host) throws Exception {
        ProposalCreate c = host.readValue(
            "{\"work_id\":\"w\",\"proposal_id\":\"proposal_1\",\"proposal\":{\"schema_version\":1}}", ProposalCreate.class);
        assertEquals("w", c.workId());
        assertEquals("proposal_1", c.proposalId());
        assertEquals(1, c.proposal().get("schema_version").asInt());

        ProposalReview r = host.readValue(
            "{\"review_id\":\"review_1\",\"reviewer_id\":\"li\",\"decision\":\"APPROVE\",\"comment\":\"ok\"}", ProposalReview.class);
        assertEquals("review_1", r.reviewId());
        assertEquals("li", r.reviewerId());

        assertEquals("review_1", host.readValue("{\"review_id\":\"review_1\"}", ProposalApply.class).reviewId());
        assertEquals("v1", host.readValue("{\"script_version\":\"v1\"}", CompileRequest.class).scriptVersion());
    }

    // ------------------------------------------------------------- responses (Java → MCP/BFF)

    @ParameterizedTest @MethodSource("hostMappers")
    void theEnvelopeIsSnakeCase(ObjectMapper host) {
        JsonNode out = host.valueToTree(AgentResponse.ok(Map.of("k", "v"), List.of("ref")));
        assertTrue(out.has("audit_refs") && out.has("next_action"));
        assertFalse(out.has("auditRefs") || out.has("nextAction"));
        assertEquals("OK", out.get("status").asText());
        assertEquals("NONE", out.get("next_action").asText());
    }

    @ParameterizedTest @MethodSource("hostMappers")
    void gapReportIsSnakeCase(ObjectMapper host) {
        GapReport report = new GapReport("work-chun-wang", List.of(new Gap("C", "HIGH", "m", "work-chun-wang")), 106, List.of("x"));
        JsonNode out = host.valueToTree(report);
        assertEquals("work-chun-wang", out.get("work_id").asText());
        assertEquals(106, out.get("audit_checks").asInt());
        assertEquals("x", out.get("audit_non_zero").get(0).asText());
        assertEquals("work-chun-wang", out.get("gaps").get(0).get("target_ref").asText());
    }

    @Test
    void snapshotIsSnakeCaseAtEveryDepthNoMatterWhatTheHostDoes() {
        Snapshot snapshot = new Snapshot(
            Map.of("id", "work-chun-wang"),
            new WorkInfo("work-chun-wang", "SHI", "dyn-tang", "place-chang-an"),
            List.of(), List.of(), List.of(), List.of(), List.of(), List.of(), List.of());
        JsonNode out = PoetryAgentWire.snake(snapshot);
        assertTrue(out.has("work_info"));
        assertFalse(out.has("workInfo"));
        assertEquals("dyn-tang", out.get("work_info").get("dynasty_id").asText());
        assertEquals("place-chang-an", out.get("work_info").get("creation_place_id").asText());
    }
}
