package com.timeline.poetry.api;

import com.timeline.poetry.api.PoetryMediaModels.Written;
import com.timeline.poetry.api.PoetryPublishModels.ScriptPublish;
import com.timeline.poetry.service.PoetryPublishService;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Human-only publish routes. They use the Studio reviewer token (poetry.studioReviewerToken), never the
 * author token and never the agent token, which must differ from it. Unset -> 503; wrong or agent token -> 401.
 */
@RestController
@RequestMapping("/api/poetry/v1")
public class PoetryPublishController {
    private final PoetryPublishService publish;
    private final String reviewerToken;
    private final String agentToken;

    public PoetryPublishController(PoetryPublishService publish, String reviewerToken, String agentToken) {
        this.publish = publish; this.reviewerToken = reviewerToken; this.agentToken = agentToken;
    }

    @PostMapping("/draft/script/{id}/{version}/publish")
    public ResponseEntity<PoetryModels.Response<Written>> publishScript(
        @RequestHeader(name = PoetryStudioWriteController.TOKEN, required = false) String token,
        @PathVariable String id, @PathVariable String version, @RequestBody ScriptPublish body) {
        ResponseEntity<PoetryModels.Response<Written>> denied = gate(token);
        if (denied != null) return denied;
        return ResponseEntity.ok(new PoetryModels.Response<>(200, publish.publishScript(id, version, body), null));
    }

    @PostMapping("/draft/asset/{id}/publish")
    public ResponseEntity<PoetryModels.Response<Written>> publishAsset(
        @RequestHeader(name = PoetryStudioWriteController.TOKEN, required = false) String token,
        @PathVariable String id) {
        ResponseEntity<PoetryModels.Response<Written>> denied = gate(token);
        if (denied != null) return denied;
        return ResponseEntity.ok(new PoetryModels.Response<>(200, publish.publishAsset(id), null));
    }

    private <T> ResponseEntity<PoetryModels.Response<T>> gate(String token) {
        if (reviewerToken == null || reviewerToken.isBlank() || reviewerToken.equals(agentToken))
            return ResponseEntity.status(503).body(new PoetryModels.Response<>(503, null,
                "poetry.studioReviewerToken is not configured (and must differ from poetry.agentInternalToken): publishing stays closed"));
        if (token == null || !MessageDigest.isEqual(reviewerToken.getBytes(StandardCharsets.UTF_8), token.getBytes(StandardCharsets.UTF_8)))
            return ResponseEntity.status(401).body(new PoetryModels.Response<>(401, null,
                "invalid or missing " + PoetryStudioWriteController.TOKEN));
        return null;
    }
}
