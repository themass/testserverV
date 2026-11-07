package com.timeline.poetry.api;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.timeline.poetry.api.PoetryStudioModels.*;
import com.timeline.poetry.service.PoetryStudioService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import jakarta.servlet.http.HttpServletRequest;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Map;

/**
 * Studio 人类写入口。头 X-Poetry-Studio-Reviewer-Token，配置项 poetry.studioReviewerToken。
 * 未配置 -> 503；缺失或错误(包括拿 agent 令牌来调) -> 401。若配置的值与 agent 令牌相同，按未配置处理(503)，
 * 否则 agent 链路就能写来源。令牌校验先于请求体解析：没有令牌的请求永远拿不到 400 的字段级提示。
 */
@RestController
@RequestMapping("/api/poetry/v1/studio")
public class PoetryStudioWriteController {
    public static final String TOKEN = "X-Poetry-Studio-Reviewer-Token";
    private static final int MAX_BODY_CHARS = 100_000;
    /** UTF-8 can use up to 4 bytes per char; the stream is never read past this many bytes. */
    private static final int MAX_BODY_BYTES = MAX_BODY_CHARS * 4;
    private final PoetryStudioService service;
    private final String reviewerToken;
    private final String agentToken;
    private final ObjectMapper strict;

    public PoetryStudioWriteController(PoetryStudioService service, String reviewerToken, String agentToken, ObjectMapper json) {
        this.service = service; this.reviewerToken = reviewerToken; this.agentToken = agentToken;
        // 复制宿主的 mapper(保留模块)，但未知字段一律拒绝：拼错键名要报错，不能静默丢掉。
        this.strict = json.copy().configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, true);
    }

    @PutMapping("/citations/{claimId}/{sourceId}/locator")
    public ResponseEntity<StudioResponse<Object>> locator(@RequestHeader(name = TOKEN, required = false) String token,
            @PathVariable String claimId, @PathVariable String sourceId, HttpServletRequest request) {
        ResponseEntity<StudioResponse<Object>> denied = gate(token); if (denied != null) return denied;
        LocatorUpdate parsed = parse(readBody(request), LocatorUpdate.class);
        return respond(service.setLocator(claimId, sourceId, parsed));
    }

    @PostMapping("/sources/{sourceId}/verification")
    public ResponseEntity<StudioResponse<Object>> verification(@RequestHeader(name = TOKEN, required = false) String token,
            @PathVariable String sourceId, HttpServletRequest request) {
        ResponseEntity<StudioResponse<Object>> denied = gate(token); if (denied != null) return denied;
        SourceVerification parsed = parse(readBody(request), SourceVerification.class);
        return respond(service.verifySource(sourceId, parsed));
    }

    @PutMapping("/proposals/{proposalId}/items")
    public ResponseEntity<StudioResponse<Object>> items(@RequestHeader(name = TOKEN, required = false) String token,
            @PathVariable String proposalId, HttpServletRequest request) {
        ResponseEntity<StudioResponse<Object>> denied = gate(token); if (denied != null) return denied;
        ItemDecisions parsed = parse(readBody(request), ItemDecisions.class);
        return respond(service.putItemDecisions(proposalId, parsed));
    }

    private ResponseEntity<StudioResponse<Object>> gate(String token) {
        if (reviewerToken == null || reviewerToken.isBlank() || reviewerToken.equals(agentToken))
            return ResponseEntity.status(503).body(widen(StudioResponse.error("UNAVAILABLE", "STUDIO_WRITE_DISABLED",
                "studio write side disabled: configure poetry.studioReviewerToken (it must differ from poetry.agentInternalToken)", null, "HUMAN_REVIEW")));
        if (token == null || !MessageDigest.isEqual(reviewerToken.getBytes(StandardCharsets.UTF_8), token.getBytes(StandardCharsets.UTF_8)))
            return ResponseEntity.status(401).body(widen(StudioResponse.error("UNAUTHORIZED", "INVALID_TOKEN", "invalid studio reviewer token", null, "HUMAN_REVIEW")));
        return null;
    }

    /**
     * Reads the request body only after the token has been accepted, and never more than MAX_BODY_BYTES.
     * With a String @RequestBody Spring had already read the whole body before this class could look at
     * the token, so an unauthenticated caller could make the server buffer an arbitrarily large payload.
     */
    private String readBody(HttpServletRequest request) {
        if (request.getContentLengthLong() > MAX_BODY_BYTES)
            throw new PoetryStudioService.Failure(400, "REJECTED", "BODY_TOO_LARGE", "request body is too large", null);
        try {
            byte[] bytes = request.getInputStream().readNBytes(MAX_BODY_BYTES + 1);
            if (bytes.length > MAX_BODY_BYTES)
                throw new PoetryStudioService.Failure(400, "REJECTED", "BODY_TOO_LARGE", "request body is too large", null);
            return new String(bytes, StandardCharsets.UTF_8);
        } catch (java.io.IOException ex) {
            throw new PoetryStudioService.Failure(400, "REJECTED", "BODY_INVALID", "request body could not be read", null);
        }
    }

    private <T> T parse(String body, Class<T> type) {
        if (body == null || body.isBlank()) throw new PoetryStudioService.Failure(400, "REJECTED", "BODY_REQUIRED", "request body is required", null);
        if (body.length() > MAX_BODY_CHARS) throw new PoetryStudioService.Failure(400, "REJECTED", "BODY_TOO_LARGE", "request body is too large", null);
        try { return strict.readValue(body, type); }
        catch (Exception ex) {
            // 不回显原始内容或异常细节，避免把请求片段写进响应/日志。
            throw new PoetryStudioService.Failure(400, "REJECTED", "BODY_INVALID",
                "request body is not valid JSON for this endpoint (check field names are snake_case and no unknown fields)", null);
        }
    }

    private static ResponseEntity<StudioResponse<Object>> respond(PoetryStudioService.Written w) {
        return ResponseEntity.ok(StudioResponse.ok((Object) w.data(), w.auditRefs()));
    }

    @SuppressWarnings("unchecked")
    private static StudioResponse<Object> widen(StudioResponse<Map<String, Object>> r) { return (StudioResponse<Object>) (StudioResponse<?>) r; }
}
