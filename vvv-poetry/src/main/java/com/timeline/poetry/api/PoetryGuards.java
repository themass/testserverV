package com.timeline.poetry.api;

import com.timeline.poetry.api.PoetryModels.Response;
import org.springframework.http.ResponseEntity;

/** Shared token posture for the write/draft side. Read side stays public on purpose. */
final class PoetryGuards {
    private PoetryGuards() {}

    /** Null means "allowed". Missing configuration -> 503, wrong token -> 401. */
    static <T> ResponseEntity<Response<T>> refuse(String header, String configuredToken, String what, String provided) {
        if (configuredToken == null || configuredToken.isBlank())
            return ResponseEntity.status(503).body(new Response<>(503, null,
                what + " disabled: configure a token (poetry.authorToken / poetry.reviewToken) to enable"));
        if (!configuredToken.equals(provided))
            return ResponseEntity.status(401).body(new Response<>(401, null, "invalid " + header));
        return null;
    }
}
