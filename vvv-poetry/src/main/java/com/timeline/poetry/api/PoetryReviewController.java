package com.timeline.poetry.api;

import com.timeline.poetry.api.PoetryModels.Response;
import com.timeline.poetry.service.AuditRunner;
import com.timeline.poetry.service.PoetryReviewService;
import com.timeline.poetry.service.PoetryReviewService.Decision;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

/**
 * Write side over HTTP. Off unless poetry.reviewToken is configured: no token configured means
 * the endpoint refuses everything with 503, because an unauthenticated write path into a real
 * database is not acceptable even when the read side is deliberately public.
 */
@RestController
@RequestMapping("/api/poetry/v1/review")
public class PoetryReviewController {
    public static final String TOKEN_HEADER = "X-Poetry-Review-Token";
    private final PoetryReviewService service;
    private final String configuredToken;

    public PoetryReviewController(PoetryReviewService service, String configuredToken) {
        this.service = service;
        this.configuredToken = configuredToken;
    }

    public record Body(String reviewer, String note) {}
    public record LogBody(String subjectId, String decision, String reviewer, String note) {}

    @PostMapping("/{type}/{id}/publish")
    public ResponseEntity<Response<Decision>> publish(@PathVariable String type, @PathVariable String id,
            @RequestHeader(name = TOKEN_HEADER, required = false) String token, @RequestBody Body body) {
        ResponseEntity<Response<Decision>> refused = refuse(type, token);
        if (refused != null) return refused;
        return answer(service.publish(type, id, body.reviewer(), body.note()));
    }

    @PostMapping("/{type}/{id}/retract")
    public ResponseEntity<Response<Decision>> retract(@PathVariable String type, @PathVariable String id,
            @RequestHeader(name = TOKEN_HEADER, required = false) String token, @RequestBody Body body) {
        ResponseEntity<Response<Decision>> refused = refuse(type, token);
        if (refused != null) return refused;
        return answer(service.retract(type, id, body.reviewer(), body.note()));
    }

    @PostMapping("/log/{type}")
    public ResponseEntity<Response<Decision>> log(@PathVariable String type,
            @RequestHeader(name = TOKEN_HEADER, required = false) String token, @RequestBody LogBody body) {
        ResponseEntity<Response<Decision>> refused = refuse(type, token);
        if (refused != null) return refused;
        return answer(service.log(type, body.subjectId(), body.decision(), body.reviewer(), body.note()));
    }

    @GetMapping("/audit")
    public ResponseEntity<Response<Map<String, Object>>> audit(
            @RequestHeader(name = TOKEN_HEADER, required = false) String token) {
        ResponseEntity<Response<Map<String, Object>>> refused = refuseGeneric(token);
        if (refused != null) return refused;
        AuditRunner.Result result = service.audit();
        return ResponseEntity.ok(Response.ok(Map.of("checks", result.totalChecks(), "nonZero", result.nonZero())));
    }

    @GetMapping("/status")
    public ResponseEntity<Response<Map<String, Object>>> status(
            @RequestHeader(name = TOKEN_HEADER, required = false) String token) {
        ResponseEntity<Response<Map<String, Object>>> refused = refuseGeneric(token);
        if (refused != null) return refused;
        return ResponseEntity.ok(Response.ok(service.status()));
    }

    private ResponseEntity<Response<Decision>> refuse(String type, String token) {
        ResponseEntity<Response<Decision>> denied =
            PoetryGuards.refuse(TOKEN_HEADER, configuredToken, "review side", token);
        if (denied != null) return denied;
        if (!Map.of("content", 1, "claim", 1, "text_version", 1, "source", 1).containsKey(type))
            return ResponseEntity.badRequest().body(new Response<>(400, null, "unsupported subject type"));
        return null;
    }

    private ResponseEntity<Response<Map<String, Object>>> refuseGeneric(String token) {
        return PoetryGuards.refuse(TOKEN_HEADER, configuredToken, "review side", token);
    }

    private static ResponseEntity<Response<Decision>> answer(Decision decision) {
        return decision.accepted() ? ResponseEntity.ok(Response.ok(decision))
            : ResponseEntity.status(409).body(new Response<>(409, decision, "publish blocked"));
    }
}
