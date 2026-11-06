package com.timeline.poetry.api;

import com.timeline.poetry.api.PoetryAgentModels.AgentResponse;
import com.timeline.poetry.api.PoetryAgentOrchestrationModels.*;
import com.timeline.poetry.service.PoetryAgentOrchestrationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

/** Internal-only persistence boundary for Poetry Studio orchestration; it has no content mutation routes. */
@RestController
@RequestMapping("/api/poetry/v1/agent-orchestration")
public class PoetryAgentOrchestrationController {
    private static final String TOKEN = PoetryAgentController.TOKEN;
    private final PoetryAgentOrchestrationService service;
    private final String internalToken;

    public PoetryAgentOrchestrationController(PoetryAgentOrchestrationService service, String internalToken) { this.service = service; this.internalToken = internalToken; }

    @PostMapping("/tasks")
    public ResponseEntity<AgentResponse<Map<String,Object>>> createTask(@RequestHeader(name=TOKEN, required=false) String token, @RequestBody TaskCreate request) { return write(token, () -> service.createTask(request), "agent-task:" + request.taskId()); }
    @GetMapping("/tasks/{taskId}")
    public ResponseEntity<AgentResponse<Map<String,Object>>> task(@RequestHeader(name=TOKEN, required=false) String token, @PathVariable String taskId) { return write(token, () -> service.task(taskId), "agent-task:" + taskId); }
    @PostMapping("/tasks/{taskId}/runs")
    public ResponseEntity<AgentResponse<Map<String,Object>>> createRun(@RequestHeader(name=TOKEN, required=false) String token, @PathVariable String taskId, @RequestBody RunCreate request) { return write(token, () -> service.createRun(taskId, request), "agent-run:" + request.runId()); }
    @GetMapping("/runs/{runId}")
    public ResponseEntity<AgentResponse<Map<String,Object>>> run(@RequestHeader(name=TOKEN, required=false) String token, @PathVariable String runId) { return write(token, () -> service.run(runId), "agent-run:" + runId); }
    @PutMapping("/runs/{runId}/admission")
    public ResponseEntity<AgentResponse<Map<String,Object>>> admission(@RequestHeader(name=TOKEN, required=false) String token, @PathVariable String runId, @RequestBody RuntimeAdmission request) { return write(token, () -> service.admitRun(runId, request), "agent-run:" + runId); }
    @PutMapping("/runs/{runId}/state")
    public ResponseEntity<AgentResponse<Map<String,Object>>> state(@RequestHeader(name=TOKEN, required=false) String token, @PathVariable String runId, @RequestBody RunStateChange request) { return write(token, () -> service.changeRunState(runId, request), "agent-run:" + runId); }
    @PostMapping("/runs/{runId}/events")
    public ResponseEntity<AgentResponse<Map<String,Object>>> event(@RequestHeader(name=TOKEN, required=false) String token, @PathVariable String runId, @RequestBody EventAppend request) { return write(token, () -> { service.appendEvent(runId, request.eventType(), request.payload()); return Map.of("run_id", runId, "recorded", true); }, "agent-run:" + runId); }
    @GetMapping("/runs/{runId}/events")
    public ResponseEntity<AgentResponse<List<Map<String,Object>>>> events(@RequestHeader(name=TOKEN, required=false) String token, @PathVariable String runId, @RequestParam(name="after_event_id", defaultValue="0") long afterEventId) {
        if (!allowed(token)) return ResponseEntity.status(403).body(AgentResponse.rejected("invalid internal Agent token"));
        try { return ResponseEntity.ok(AgentResponse.ok(service.events(runId, afterEventId), List.of("agent-events:" + runId))); }
        catch (PoetryAgentOrchestrationService.Rejected e) { return ResponseEntity.badRequest().body(AgentResponse.rejected(e.getMessage())); }
    }
    @GetMapping("/proposals/{proposalId}")
    public ResponseEntity<AgentResponse<Map<String,Object>>> proposal(@RequestHeader(name=TOKEN, required=false) String token, @PathVariable String proposalId) { return write(token, () -> service.proposal(proposalId), "agent-proposal:" + proposalId); }

    private ResponseEntity<AgentResponse<Map<String,Object>>> write(String token, Work work, String ref) {
        if (!allowed(token)) return ResponseEntity.status(403).body(AgentResponse.rejected("invalid internal Agent token"));
        try { return ResponseEntity.ok(AgentResponse.ok(work.get(), List.of(ref))); }
        catch (PoetryAgentOrchestrationService.Conflict e) { return ResponseEntity.status(409).body(AgentResponse.conflict(e.getMessage())); }
        catch (PoetryAgentOrchestrationService.Rejected e) { return ResponseEntity.badRequest().body(AgentResponse.rejected(e.getMessage())); }
    }
    private boolean allowed(String token) { return internalToken != null && !internalToken.isBlank() && internalToken.equals(token); }
    @FunctionalInterface private interface Work { Map<String,Object> get(); }
}
