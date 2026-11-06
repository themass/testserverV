package com.timeline.poetry.api;

import com.timeline.poetry.api.PoetryMediaModels.*;
import com.timeline.poetry.api.PoetryModels.Response;
import com.timeline.poetry.service.PoetryMediaService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

/**
 * Read side: PUBLISHED assets/scripts only, fail-closed like the rest of the API.
 * Write side: DRAFT only, token required. Nothing here publishes or retires a bundle.
 */
@RestController
@RequestMapping("/api/poetry/v1")
public class PoetryMediaController {
    public static final String TOKEN_HEADER = "X-Poetry-Draft-Token";
    private final PoetryMediaService media;
    private final String token;

    public PoetryMediaController(PoetryMediaService media, String token) {
        this.media = media; this.token = token;
    }

    @GetMapping("/assets")
    public ResponseEntity<Response<List<Asset>>> assets(
        @RequestHeader(name = TOKEN_HEADER, required = false) String provided,
        @RequestParam(required = false) String level,
        @RequestParam(defaultValue = "50") int limit, @RequestParam(defaultValue = "0") int offset) {
        ResponseEntity<Response<List<Asset>>> denied = refuse(provided);
        if (denied != null) return denied;
        return ok(new Response<>(200, media.assets(level, limit, offset), null));
    }

    @GetMapping("/assets/{id}")
    public ResponseEntity<Response<Asset>> asset(
        @RequestHeader(name = TOKEN_HEADER, required = false) String provided, @PathVariable String id) {
        ResponseEntity<Response<Asset>> denied = refuse(provided);
        if (denied != null) return denied;
        return ok(new Response<>(200, media.asset(id), null));
    }

    @GetMapping("/assets/{id}/chain")
    public ResponseEntity<Response<Chain>> chain(
        @RequestHeader(name = TOKEN_HEADER, required = false) String provided, @PathVariable String id) {
        ResponseEntity<Response<Chain>> denied = refuse(provided);
        if (denied != null) return denied;
        return ok(new Response<>(200, media.chain(id), null));
    }

    @GetMapping("/scripts")
    public ResponseEntity<Response<List<Script>>> scripts(
        @RequestHeader(name = TOKEN_HEADER, required = false) String provided,
        @RequestParam(defaultValue = "20") int limit, @RequestParam(defaultValue = "0") int offset) {
        ResponseEntity<Response<List<Script>>> denied = refuse(provided);
        if (denied != null) return denied;
        return ok(new Response<>(200, media.scripts(limit, offset), null));
    }

    @GetMapping("/scripts/{id}")
    public ResponseEntity<Response<ScriptDetail>> script(
        @RequestHeader(name = TOKEN_HEADER, required = false) String provided, @PathVariable String id) {
        ResponseEntity<Response<ScriptDetail>> denied = refuse(provided);
        if (denied != null) return denied;
        return ok(new Response<>(200, media.scriptDetail(id), null));
    }

    @PostMapping("/draft/asset/{id}")
    public ResponseEntity<Response<Written>> createAsset(
        @RequestHeader(name = TOKEN_HEADER, required = false) String provided,
        @PathVariable String id, @RequestBody AssetWrite body) {
        ResponseEntity<Response<Written>> denied = refuse(provided);
        if (denied != null) return denied;
        return ok(new Response<>(200, media.createAsset(id, body), null));
    }

    @PutMapping("/draft/asset/{id}")
    public ResponseEntity<Response<Written>> updateAsset(
        @RequestHeader(name = TOKEN_HEADER, required = false) String provided,
        @PathVariable String id, @RequestBody AssetWrite body) {
        ResponseEntity<Response<Written>> denied = refuse(provided);
        if (denied != null) return denied;
        return ok(new Response<>(200, media.updateAsset(id, body), null));
    }

    @PostMapping("/draft/script/{id}/{version}")
    public ResponseEntity<Response<Written>> createScript(
        @RequestHeader(name = TOKEN_HEADER, required = false) String provided,
        @PathVariable String id, @PathVariable String version, @RequestBody ScriptWrite body) {
        ResponseEntity<Response<Written>> denied = refuse(provided);
        if (denied != null) return denied;
        return ok(new Response<>(200, media.createScript(id, version, body), null));
    }

    /** The bundle compiler's bookkeeping entry point: which asset this script version actually pulls. */
    @PostMapping("/draft/script/{id}/{version}/assets")
    public ResponseEntity<Response<Integer>> registerAssets(
        @RequestHeader(name = TOKEN_HEADER, required = false) String provided,
        @PathVariable String id, @PathVariable String version, @RequestBody List<ScriptAssetWrite> body) {
        ResponseEntity<Response<Integer>> denied = refuse(provided);
        if (denied != null) return denied;
        return ok(new Response<>(200, media.registerAssets(id, version, body), null));
    }

    private static <T> ResponseEntity<Response<T>> ok(Response<T> body) { return ResponseEntity.ok(body); }

    private <T> ResponseEntity<Response<T>> refuse(String provided) {
        if (token == null || token.isBlank())
            return ResponseEntity.status(503).body(new Response<>(503, null,
                "poetry.authorToken is not configured: media endpoints stay closed"));
        if (provided == null || !provided.equals(token))
            return ResponseEntity.status(401).body(new Response<>(401, null, "invalid or missing " + TOKEN_HEADER));
        return null;
    }
}
