package com.timeline.poetry.api;

import com.timeline.poetry.api.PoetryAgentModels.*;
import com.timeline.poetry.service.PoetryAgentService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

/** Internal-only boundary used by Poetry Domain MCP; no student route reaches this controller. */
@RestController
@RequestMapping("/api/poetry/v1")
public class PoetryAgentController {
    public static final String TOKEN = "X-Poetry-Agent-Internal-Token";
    public static final String RUN = "X-Poetry-Agent-Run-Id";
    public static final String MANDATE = "X-Poetry-Agent-Mandate-Id";
    public static final String ROLE = "X-Poetry-Agent-Role";
    private final PoetryAgentService service;
    private final String internalToken;

    public PoetryAgentController(PoetryAgentService service, String internalToken) { this.service = service; this.internalToken = internalToken; }

    @GetMapping("/works/{workId}/snapshot")
    public ResponseEntity<AgentResponse<Snapshot>> snapshot(@PathVariable String workId, @RequestHeader(name=TOKEN, required=false) String token,
            @RequestHeader(name=RUN, required=false) String run, @RequestHeader(name=MANDATE, required=false) String mandate,
            @RequestHeader(name="Idempotency-Key", required=false) String key, @RequestHeader(name=ROLE, required=false) String role) {
        AgentResponse<Snapshot> denied = authorize(token, run, mandate, key, role); if (denied != null) return ResponseEntity.status(403).body(denied);
        try { return ResponseEntity.ok(AgentResponse.ok(service.snapshot(workId), List.of("snapshot:" + workId))); }
        catch (PoetryAgentService.Rejected e) { return ResponseEntity.badRequest().body(AgentResponse.rejected(e.getMessage())); }
    }

    @GetMapping("/works/{workId}/integrity-gap-report")
    public ResponseEntity<AgentResponse<GapReport>> gaps(@PathVariable String workId, @RequestHeader(name=TOKEN, required=false) String token,
            @RequestHeader(name=RUN, required=false) String run, @RequestHeader(name=MANDATE, required=false) String mandate,
            @RequestHeader(name="Idempotency-Key", required=false) String key, @RequestHeader(name=ROLE, required=false) String role) {
        AgentResponse<GapReport> denied = authorize(token, run, mandate, key, role); if (denied != null) return ResponseEntity.status(403).body(denied);
        try { return ResponseEntity.ok(AgentResponse.ok(service.gaps(workId), List.of("gap-report:" + workId))); }
        catch (PoetryAgentService.Rejected e) { return ResponseEntity.badRequest().body(AgentResponse.rejected(e.getMessage())); }
    }

    @PostMapping("/draft/proposals")
    public ResponseEntity<AgentResponse<Map<String,Object>>> create(@RequestHeader(name=TOKEN, required=false) String token,
            @RequestHeader(name=RUN, required=false) String run, @RequestHeader(name=MANDATE, required=false) String mandate,
            @RequestHeader(name="Idempotency-Key", required=false) String key, @RequestHeader(name=ROLE, required=false) String role,
            @RequestBody ProposalCreate body) { return write(token, run, mandate, key, role, c -> service.createProposal(c, body)); }

    /** This endpoint is BFF-only in deployment policy; it records a human decision before DRAFT apply. */
    @PostMapping("/draft/proposals/{proposalId}/reviews")
    public ResponseEntity<AgentResponse<Map<String,Object>>> review(@PathVariable String proposalId, @RequestHeader(name=TOKEN, required=false) String token,
            @RequestHeader(name=RUN, required=false) String run, @RequestHeader(name=MANDATE, required=false) String mandate,
            @RequestHeader(name="Idempotency-Key", required=false) String key, @RequestHeader(name=ROLE, required=false) String role,
            @RequestBody ProposalReview body) { return write(token, run, mandate, key, role, c -> service.reviewProposal(c, proposalId, body)); }

    @PostMapping("/draft/proposals/{proposalId}/apply")
    public ResponseEntity<AgentResponse<Map<String,Object>>> apply(@PathVariable String proposalId, @RequestHeader(name=TOKEN, required=false) String token,
            @RequestHeader(name=RUN, required=false) String run, @RequestHeader(name=MANDATE, required=false) String mandate,
            @RequestHeader(name="Idempotency-Key", required=false) String key, @RequestHeader(name=ROLE, required=false) String role,
            @RequestBody ProposalApply body) { return write(token, run, mandate, key, role, c -> service.apply(c, proposalId, body)); }

    @PostMapping("/works/{workId}/compile-requests")
    public ResponseEntity<AgentResponse<Map<String,Object>>> compile(@PathVariable String workId, @RequestHeader(name=TOKEN, required=false) String token,
            @RequestHeader(name=RUN, required=false) String run, @RequestHeader(name=MANDATE, required=false) String mandate,
            @RequestHeader(name="Idempotency-Key", required=false) String key, @RequestHeader(name=ROLE, required=false) String role,
            @RequestBody CompileRequest body) { return write(token, run, mandate, key, role, c -> service.requestCompile(c, workId, body)); }

    private ResponseEntity<AgentResponse<Map<String,Object>>> write(String token, String run, String mandate, String key, String role, WriteCall call) {
        AgentResponse<Map<String,Object>> denied = authorize(token, run, mandate, key, role); if (denied != null) return ResponseEntity.status(403).body(denied);
        try { return ResponseEntity.ok(call.run(new PoetryAgentService.Context(run, mandate, key, role))); }
        catch (PoetryAgentService.Conflict e) { return ResponseEntity.status(409).body(AgentResponse.conflict(e.getMessage())); }
        catch (PoetryAgentService.Rejected e) { return ResponseEntity.badRequest().body(AgentResponse.rejected(e.getMessage())); }
    }
    private <T> AgentResponse<T> authorize(String token, String run, String mandate, String key, String role) {
        if (internalToken == null || internalToken.isBlank()) return AgentResponse.rejected("agent domain API disabled: configure poetry.agentInternalToken");
        if (!internalToken.equals(token)) return AgentResponse.rejected("invalid internal Agent token");
        if (blank(run) || blank(mandate) || blank(key)) return AgentResponse.rejected("run, mandate and Idempotency-Key headers are required");
        if (key.length() > 128) return AgentResponse.rejected("Idempotency-Key may not exceed 128 characters");
        // Role is retained as audit context only. The deployment token is the authorization decision.
        if (!("CONTENT_EDITOR".equals(role) || "HISTORICAL_REVIEWER".equals(role))) return AgentResponse.rejected("unsupported agent audit role");
        return null;
    }
    private static boolean blank(String v) { return v == null || v.isBlank(); }
    @FunctionalInterface private interface WriteCall { AgentResponse<Map<String,Object>> run(PoetryAgentService.Context c); }
}
