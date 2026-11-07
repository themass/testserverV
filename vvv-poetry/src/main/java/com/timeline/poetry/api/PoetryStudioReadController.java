package com.timeline.poetry.api;

import com.timeline.poetry.api.PoetryStudioModels.StudioResponse;
import com.timeline.poetry.service.PoetryStudioService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.List;
import java.util.Map;

/**
 * Studio 只读路由(经 MCP 控制桥转发)。头 X-Poetry-Agent-Internal-Token，不要求 run/mandate 头。
 * 与既有 {@link PoetryAgentOrchestrationController} 共用前缀；只新增 GET 路由，和它已有的
 * /tasks/{taskId}、/proposals/{proposalId} 不冲突(这里是 /tasks、/tasks/{id}/runs、/proposals、/proposals/{id}/items 等)。
 * 令牌未配置或不匹配与该控制器一致：403。
 */
@RestController
@RequestMapping("/api/poetry/v1/agent-orchestration")
public class PoetryStudioReadController {
    private static final String TOKEN = PoetryAgentController.TOKEN;
    private final PoetryStudioService service;
    private final String internalToken;

    public PoetryStudioReadController(PoetryStudioService service, String internalToken) { this.service = service; this.internalToken = internalToken; }

    @GetMapping("/tasks")
    public ResponseEntity<StudioResponse<Object>> tasks(@RequestHeader(name = TOKEN, required = false) String token,
            @RequestParam(name = "work_id", required = false) String workId, @RequestParam(name = "status", required = false) String status,
            @RequestParam(name = "task_type", required = false) String taskType, @RequestParam(name = "limit", required = false) String limit,
            @RequestParam(name = "offset", required = false) String offset) {
        return read(token, "agent-tasks", () -> service.tasks(workId, status, taskType, limit, offset));
    }

    @GetMapping("/tasks/{taskId}/runs")
    public ResponseEntity<StudioResponse<Object>> taskRuns(@RequestHeader(name = TOKEN, required = false) String token, @PathVariable String taskId) {
        return read(token, "agent-task-runs:" + taskId, () -> service.taskRuns(taskId));
    }

    @GetMapping("/proposals")
    public ResponseEntity<StudioResponse<Object>> proposals(@RequestHeader(name = TOKEN, required = false) String token,
            @RequestParam(name = "work_id", required = false) String workId, @RequestParam(name = "status", required = false) String status,
            @RequestParam(name = "review_status", required = false) String reviewStatus, @RequestParam(name = "run_id", required = false) String runId,
            @RequestParam(name = "task_id", required = false) String taskId, @RequestParam(name = "limit", required = false) String limit,
            @RequestParam(name = "offset", required = false) String offset) {
        return read(token, "agent-proposals", () -> service.proposals(workId, status, reviewStatus, runId, taskId, limit, offset));
    }

    @GetMapping("/proposals/{proposalId}/items")
    public ResponseEntity<StudioResponse<Object>> proposalItems(@RequestHeader(name = TOKEN, required = false) String token, @PathVariable String proposalId) {
        return read(token, "agent-proposal-items:" + proposalId, () -> service.proposalItems(proposalId));
    }

    @GetMapping("/works")
    public ResponseEntity<StudioResponse<Object>> works(@RequestHeader(name = TOKEN, required = false) String token,
            @RequestParam(name = "limit", required = false) String limit, @RequestParam(name = "offset", required = false) String offset) {
        return read(token, "studio-works", () -> service.works(limit, offset));
    }

    @GetMapping("/works/{workId}/coverage")
    public ResponseEntity<StudioResponse<Object>> coverage(@RequestHeader(name = TOKEN, required = false) String token, @PathVariable String workId) {
        return read(token, "coverage:" + workId, () -> service.coverage(workId));
    }

    @GetMapping("/works/{workId}/studio-view")
    public ResponseEntity<StudioResponse<Object>> studioView(@RequestHeader(name = TOKEN, required = false) String token, @PathVariable String workId) {
        return read(token, "studio-view:" + workId, () -> service.studioView(workId));
    }

    @GetMapping("/sources")
    public ResponseEntity<StudioResponse<Object>> sources(@RequestHeader(name = TOKEN, required = false) String token,
            @RequestParam(name = "verification_status", required = false) String verificationStatus,
            @RequestParam(name = "limit", required = false) String limit, @RequestParam(name = "offset", required = false) String offset) {
        return read(token, "studio-sources", () -> service.sources(verificationStatus, limit, offset));
    }

    private ResponseEntity<StudioResponse<Object>> read(String token, String ref, Read read) {
        if (!allowed(token)) return ResponseEntity.status(403).body(cast(StudioResponse.error("REJECTED", "INVALID_TOKEN", "invalid internal Agent token", null, "REPLAN")));
        return ResponseEntity.ok(StudioResponse.ok(read.get(), List.of(ref)));
    }

    private boolean allowed(String token) {
        if (internalToken == null || internalToken.isBlank() || token == null) return false;
        return MessageDigest.isEqual(internalToken.getBytes(StandardCharsets.UTF_8), token.getBytes(StandardCharsets.UTF_8));
    }

    @SuppressWarnings("unchecked")
    private static StudioResponse<Object> cast(StudioResponse<Map<String, Object>> r) { return (StudioResponse<Object>) (StudioResponse<?>) r; }
    @FunctionalInterface private interface Read { Object get(); }
}
