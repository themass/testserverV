package com.timeline.student.api;

import com.timeline.student.api.StudentModels.*;
import com.timeline.student.service.ContentService;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import java.time.Duration;
import java.util.List;

/**
 * Public, token-free, read-only. Everything returned is PUBLISHED content; see ContentService.
 * Bundles are content-addressed, so they are cacheable forever.
 */
@RestController
@RequestMapping("/api/student/v1")
public class StudentContentController {
    private final ContentService content;
    private final Config config;

    public StudentContentController(ContentService content, Config config) {
        this.content = content; this.config = config;
    }

    @GetMapping("/config")
    public Response<Config> config() { return Response.ok(config); }

    @GetMapping("/timeline")
    public Response<TimelineView> timeline(@RequestParam(required = false) String type,
                                           @RequestParam int fromYear, @RequestParam int toYear,
                                           @RequestParam(defaultValue = "50") int limit,
                                           @RequestParam(defaultValue = "0") int offset) {
        return Response.ok(content.timeline(type, fromYear, toYear, limit, offset));
    }

    @GetMapping("/overview")
    public Response<Overview> overview() { return Response.ok(content.overview()); }

    @GetMapping("/works")
    public Response<List<WorkCard>> works() { return Response.ok(content.works()); }

    @GetMapping("/works/{workId}")
    public Response<WorkCard> work(@PathVariable String workId) { return Response.ok(content.work(workId)); }

    @GetMapping("/works/{workId}/lesson")
    public Response<LessonEntry> lesson(@PathVariable String workId) { return Response.ok(content.lesson(workId)); }

    @GetMapping("/works/{workId}/pack")
    public Response<Pack> pack(@PathVariable String workId) { return Response.ok(content.pack(workId)); }

    @GetMapping(value = "/bundles/{hash}", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<byte[]> bundle(@PathVariable String hash) {
        return immutable(hash, content.bundle(hash));
    }

    @GetMapping(value = "/bundles/{hash}/manifest", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<byte[]> manifest(@PathVariable String hash) {
        return immutable(hash, content.manifest(hash));
    }

    /** Published claims only; PoetryCatalog answers 404 for anything else, which StudentAdvice passes through. */
    @GetMapping("/claims/{claimId}/citations")
    public Response<List<CitationItem>> citations(@PathVariable String claimId) {
        return Response.ok(content.citations(claimId));
    }

    @GetMapping("/assets")
    public Response<List<AssetRow>> assets(@RequestParam(required = false) String level,
                                           @RequestParam(defaultValue = "100") int limit,
                                           @RequestParam(defaultValue = "0") int offset) {
        return Response.ok(content.assets(level, limit, offset));
    }

    @GetMapping("/assets/{id}/chain")
    public Response<AssetChain> chain(@PathVariable String id) { return Response.ok(content.chain(id)); }

    private static ResponseEntity<byte[]> immutable(String hash, byte[] body) {
        return ResponseEntity.ok()
            .cacheControl(CacheControl.maxAge(Duration.ofDays(365)).cachePublic().immutable())
            .eTag("\"" + hash + "\"")
            .contentType(MediaType.APPLICATION_JSON)
            .body(body);
    }
}
