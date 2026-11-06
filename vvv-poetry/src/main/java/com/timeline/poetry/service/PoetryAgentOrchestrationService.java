package com.timeline.poetry.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.timeline.poetry.api.PoetryAgentOrchestrationModels.*;
import com.timeline.poetry.persistence.PoetryAgentOrchestrationMapper;
import org.springframework.transaction.annotation.Transactional;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** Durable state machine behind Poetry Studio. This service intentionally has no content mutation API. */
public class PoetryAgentOrchestrationService {
    private static final Set<String> TASK_TYPES = Set.of("GAP_ANALYSIS", "ANNOTATION_DRAFT", "SCRIPT_DRAFT", "COMPILE_TRIAGE");
    private static final Set<String> ROLES = Set.of("CONTENT_EDITOR", "HISTORICAL_REVIEWER", "RELEASE_MANAGER", "PLATFORM_ADMIN");
    private static final Set<String> RUN_STATES = Set.of("RUNNING", "WAITING_FOR_RUNTIME", "AWAITING_REVIEW", "COMPLETED", "FAILED");
    private final PoetryAgentOrchestrationMapper mapper;
    private final PoetryAgentService domain;
    private final ObjectMapper json;

    public PoetryAgentOrchestrationService(PoetryAgentOrchestrationMapper mapper, PoetryAgentService domain, ObjectMapper json) { this.mapper = mapper; this.domain = domain; this.json = json; }

    @Transactional
    public Map<String,Object> createTask(TaskCreate request) {
        requireId(request.taskId(), "task_"); requireWork(request.workId());
        if (!TASK_TYPES.contains(request.taskType())) throw new Rejected("unsupported task type");
        if (!ROLES.contains(request.requestedRole())) throw new Rejected("unsupported requested role");
        if (blank(request.title()) || request.title().length() > 200 || blank(request.instructions()) || request.instructions().length() > 8000) throw new Rejected("task title or instructions invalid");
        if (blank(request.requestedBy()) || request.requestedBy().length() > 100 || blank(request.requestedProfile()) || request.requestedProfile().length() > 64) throw new Rejected("task actor or profile invalid");
        if (mapper.taskExists(request.taskId()) != 0) throw new Conflict("task already exists");
        mapper.insertTask(request.taskId(), request.workId(), request.title(), request.taskType(), request.requestedBy(), request.requestedRole(), request.instructions(), request.requestedProfile());
        return task(request.taskId());
    }

    @Transactional
    public Map<String,Object> createRun(String taskId, RunCreate request) {
        Map<String,Object> task = task(taskId); requireId(request.runId(), "run_"); requireId(request.mandateId(), "mandate_");
        if (mapper.runExists(request.runId()) != 0) throw new Conflict("run already exists");
        if (!("DEERFLOW".equals(request.runtime()) || "STUB".equals(request.runtime()))) throw new Rejected("unsupported runtime");
        if (blank(request.profileName()) || blank(request.profileFingerprint()) || !request.profileFingerprint().matches("[a-f0-9]{64}") || request.profileManifest() == null || !request.profileManifest().isObject()) throw new Rejected("profile identity invalid");
        String workId = string(task, "work_id"); String role = string(task, "requested_role");
        mapper.ensureProfile(request.profileFingerprint(), request.profileName(), serialize(request.profileManifest()));
        mapper.insertRun(request.runId(), taskId, request.mandateId(), request.runtime(), request.profileName(), request.profileFingerprint());
        mapper.insertMandate(request.runId(), request.mandateId(), workId, role);
        mapper.taskState(taskId, "RUNNING", request.runId());
        appendEvent(request.runId(), "RUN_CREATED", json.valueToTree(Map.of("task_id", taskId, "mandate_id", request.mandateId(), "runtime", request.runtime())));
        return run(request.runId());
    }

    @Transactional
    public Map<String,Object> admitRun(String runId, RuntimeAdmission request) {
        run(runId); requireRunState(request.status());
        mapper.admitRun(runId, request.status(), nullable(request.runtimeThreadId(), 128), nullable(request.runtimeRunId(), 128), nullable(request.reason(), 4000));
        Map<String,Object> current = run(runId); mapper.taskState(string(current, "task_id"), request.status(), runId);
        appendEvent(runId, "RUNTIME_ADMISSION", json.valueToTree(Map.of("status", request.status(), "runtime_thread_id", nullToEmpty(request.runtimeThreadId()), "runtime_run_id", nullToEmpty(request.runtimeRunId()), "reason", nullToEmpty(request.reason()))));
        return run(runId);
    }

    @Transactional
    public Map<String,Object> changeRunState(String runId, RunStateChange request) {
        Map<String,Object> current = run(runId); requireRunState(request.status());
        mapper.runState(runId, request.status(), nullable(request.reason(), 4000));
        mapper.taskState(string(current, "task_id"), request.status(), runId);
        appendEvent(runId, "RUN_STATE_CHANGED", json.valueToTree(Map.of("status", request.status(), "reason", nullToEmpty(request.reason()))));
        return run(runId);
    }

    @Transactional
    public void appendEvent(String runId, String eventType, JsonNode payload) {
        run(runId);
        if (blank(eventType) || eventType.length() > 64) throw new Rejected("event type invalid");
        mapper.insertEvent(runId, eventType, payload == null ? "{}" : serialize(payload));
    }

    public Map<String,Object> task(String taskId) { Map<String,Object> task = mapper.task(taskId); if (task == null) throw new Rejected("task not found"); return task; }
    public Map<String,Object> run(String runId) { Map<String,Object> run = mapper.run(runId); if (run == null) throw new Rejected("run not found"); return run; }
    public Map<String,Object> proposal(String proposalId) { Map<String,Object> proposal = mapper.proposal(proposalId); if (proposal == null) throw new Rejected("proposal not found"); return proposal; }
    public List<Map<String,Object>> events(String runId, long afterId) { run(runId); if (afterId < 0) throw new Rejected("after_event_id invalid"); return mapper.events(runId, afterId, 250); }

    private void requireWork(String workId) { domain.snapshot(workId); }
    private static void requireId(String id, String prefix) { if (blank(id) || !id.startsWith(prefix) || id.length() > 64) throw new Rejected("invalid " + prefix + " identifier"); }
    private static void requireRunState(String state) { if (!RUN_STATES.contains(state)) throw new Rejected("unsupported run state"); }
    private String serialize(JsonNode value) { try { return json.writeValueAsString(value); } catch (JsonProcessingException e) { throw new Rejected("cannot serialize agent payload"); } }
    private static String string(Map<String,Object> value, String name) { Object field = value.get(name); if (field == null || field.toString().isBlank()) throw new Rejected("durable state is incomplete: " + name); return field.toString(); }
    private static String nullable(String value, int max) { if (value == null) return null; if (value.length() > max) throw new Rejected("field too long"); return value; }
    private static String nullToEmpty(String value) { return value == null ? "" : value; }
    private static boolean blank(String value) { return value == null || value.isBlank(); }
    public static class Rejected extends RuntimeException { public Rejected(String message) { super(message); } }
    public static class Conflict extends RuntimeException { public Conflict(String message) { super(message); } }
}
