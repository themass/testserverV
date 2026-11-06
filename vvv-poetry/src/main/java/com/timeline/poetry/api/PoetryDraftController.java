package com.timeline.poetry.api;

import com.timeline.poetry.api.PoetryDraftModels.*;
import com.timeline.poetry.api.PoetryModels.Response;
import com.timeline.poetry.service.PoetryDraftService;
import com.timeline.poetry.service.PoetryTextService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

/**
 * Draft authoring over HTTP. Token required, same posture as the review endpoints.
 * There is no DELETE: withdrawal is POST /review/{type}/{id}/retract (status=RETRACTED),
 * because removing a parent row would create exactly the orphans the 106 audit checks look for.
 */
@RestController
@RequestMapping("/api/poetry/v1/draft")
public class PoetryDraftController {
    public static final String TOKEN_HEADER = "X-Poetry-Draft-Token";
    private final PoetryDraftService service;
    private final PoetryTextService texts;
    private final String token;

    public PoetryDraftController(PoetryDraftService service, PoetryTextService texts, String token) {
        this.service = service;
        this.texts = texts;
        this.token = token;
    }

    @PostMapping("/content")
    public ResponseEntity<Response<Written>> createContent(@RequestHeader(name = TOKEN_HEADER, required = false) String provided,
                                                           @RequestBody ContentCreate body) {
        ResponseEntity<Response<Written>> denied = refuse(provided, "authoring");
        if (denied != null) return denied;
        return ok(service.createContent(body));
    }

    @PutMapping("/content/{id}")
    public ResponseEntity<Response<Written>> updateContent(@RequestHeader(name = TOKEN_HEADER, required = false) String provided,
                                                            @PathVariable String id, @RequestBody ContentUpdate body) {
        ResponseEntity<Response<Written>> denied = refuse(provided, "authoring");
        if (denied != null) return denied;
        return ok(service.updateContent(id, body));
    }

    @PostMapping("/source")
    public ResponseEntity<Response<Written>> createSource(@RequestHeader(name = TOKEN_HEADER, required = false) String provided,
                                                           @RequestBody SourceCreate body) {
        ResponseEntity<Response<Written>> denied = refuse(provided, "authoring");
        if (denied != null) return denied;
        return ok(service.createSource(body));
    }

    @PutMapping("/source/{id}")
    public ResponseEntity<Response<Written>> updateSource(@RequestHeader(name = TOKEN_HEADER, required = false) String provided,
                                                           @PathVariable String id, @RequestBody SourceUpdate body) {
        ResponseEntity<Response<Written>> denied = refuse(provided, "authoring");
        if (denied != null) return denied;
        return ok(service.updateSource(id, body));
    }

    @PostMapping("/claim")
    public ResponseEntity<Response<Written>> createClaim(@RequestHeader(name = TOKEN_HEADER, required = false) String provided,
                                                          @RequestBody ClaimCreate body) {
        ResponseEntity<Response<Written>> denied = refuse(provided, "authoring");
        if (denied != null) return denied;
        return ok(service.createClaim(body));
    }

    @PutMapping("/claim/{id}")
    public ResponseEntity<Response<Written>> updateClaim(@RequestHeader(name = TOKEN_HEADER, required = false) String provided,
                                                          @PathVariable String id, @RequestBody ClaimUpdate body) {
        ResponseEntity<Response<Written>> denied = refuse(provided, "authoring");
        if (denied != null) return denied;
        return ok(service.updateClaim(id, body));
    }

    @PostMapping("/citation")
    public ResponseEntity<Response<Written>> cite(@RequestHeader(name = TOKEN_HEADER, required = false) String provided,
                                                   @RequestBody CitationCreate body) {
        ResponseEntity<Response<Written>> denied = refuse(provided, "authoring");
        if (denied != null) return denied;
        return ok(service.cite(body));
    }

    @PostMapping("/adopt")
    public ResponseEntity<Response<Written>> adopt(@RequestHeader(name = TOKEN_HEADER, required = false) String provided,
                                                    @RequestBody Adoption body) {
        ResponseEntity<Response<Written>> denied = refuse(provided, "authoring");
        if (denied != null) return denied;
        return ok(service.adopt(body));
    }

    @PostMapping("/coverage")
    public ResponseEntity<Response<Written>> coverage(@RequestHeader(name = TOKEN_HEADER, required = false) String provided,
                                                       @RequestBody CoverageWrite body) {
        ResponseEntity<Response<Written>> denied = refuse(provided, "authoring");
        if (denied != null) return denied;
        return ok(service.upsertCoverage(body));
    }

    @GetMapping("/content")
    public ResponseEntity<Response<List<DraftContent>>> contents(
            @RequestHeader(name = TOKEN_HEADER, required = false) String provided,
            @RequestParam(required = false) String type, @RequestParam(required = false) String status,
            @RequestParam(required = false) String q, @RequestParam(defaultValue = "50") int limit,
            @RequestParam(defaultValue = "0") int offset) {
        ResponseEntity<Response<List<DraftContent>>> denied = refuse(provided, "draft reads");
        if (denied != null) return denied;
        return ResponseEntity.ok(Response.ok(service.contents(type, status, q, Math.min(200, Math.max(1, limit)), Math.max(0, offset))));
    }

    @GetMapping("/content/{id}")
    public ResponseEntity<Response<DraftContent>> content(
            @RequestHeader(name = TOKEN_HEADER, required = false) String provided, @PathVariable String id) {
        ResponseEntity<Response<DraftContent>> denied = refuse(provided, "draft reads");
        if (denied != null) return denied;
        DraftContent found = service.content(id);
        return found == null ? ResponseEntity.status(404).body(new Response<>(404, null, "not found"))
            : ResponseEntity.ok(Response.ok(found));
    }

    @GetMapping("/content/{id}/claims")
    public ResponseEntity<Response<List<DraftClaim>>> claims(
            @RequestHeader(name = TOKEN_HEADER, required = false) String provided, @PathVariable String id) {
        ResponseEntity<Response<List<DraftClaim>>> denied = refuse(provided, "draft reads");
        if (denied != null) return denied;
        return ResponseEntity.ok(Response.ok(service.claims(id)));
    }

    @GetMapping("/content/{id}/selections")
    public ResponseEntity<Response<List<DraftSelection>>> selections(
            @RequestHeader(name = TOKEN_HEADER, required = false) String provided, @PathVariable String id) {
        ResponseEntity<Response<List<DraftSelection>>> denied = refuse(provided, "draft reads");
        if (denied != null) return denied;
        return ResponseEntity.ok(Response.ok(service.selections(id)));
    }

    @GetMapping("/claim/{id}/citations")
    public ResponseEntity<Response<List<DraftCitation>>> citations(
            @RequestHeader(name = TOKEN_HEADER, required = false) String provided, @PathVariable String id) {
        ResponseEntity<Response<List<DraftCitation>>> denied = refuse(provided, "draft reads");
        if (denied != null) return denied;
        return ResponseEntity.ok(Response.ok(service.citations(id)));
    }

    @GetMapping("/source")
    public ResponseEntity<Response<List<DraftSource>>> sources(
            @RequestHeader(name = TOKEN_HEADER, required = false) String provided,
            @RequestParam(required = false) String status, @RequestParam(defaultValue = "50") int limit,
            @RequestParam(defaultValue = "0") int offset) {
        ResponseEntity<Response<List<DraftSource>>> denied = refuse(provided, "draft reads");
        if (denied != null) return denied;
        return ResponseEntity.ok(Response.ok(service.sources(status, Math.min(200, Math.max(1, limit)), Math.max(0, offset))));
    }

    @GetMapping("/coverage")
    public ResponseEntity<Response<List<DraftCoverage>>> coverage(
            @RequestHeader(name = TOKEN_HEADER, required = false) String provided,
            @RequestParam(required = false) String type) {
        ResponseEntity<Response<List<DraftCoverage>>> denied = refuse(provided, "draft reads");
        if (denied != null) return denied;
        return ResponseEntity.ok(Response.ok(service.coverage(type)));
    }


    // ---------------- slice 2: text versions, lines, backgrounds, annotations, relations, authorship, textbooks

    @PostMapping("/version")
    public ResponseEntity<Response<Written>> createVersion(@RequestHeader(name = TOKEN_HEADER, required = false) String provided,
                                                            @RequestBody VersionCreate body) {
        ResponseEntity<Response<Written>> denied = refuse(provided, "authoring");
        if (denied != null) return denied;
        return ok(texts.createVersion(body));
    }

    @PutMapping("/version/{id}")
    public ResponseEntity<Response<Written>> updateVersion(@RequestHeader(name = TOKEN_HEADER, required = false) String provided,
                                                            @PathVariable String id, @RequestBody VersionUpdate body) {
        ResponseEntity<Response<Written>> denied = refuse(provided, "authoring");
        if (denied != null) return denied;
        return ok(texts.updateVersion(id, body));
    }

    @GetMapping("/versions")
    public ResponseEntity<Response<List<DraftVersion>>> versions(@RequestHeader(name = TOKEN_HEADER, required = false) String provided,
                                                                  @RequestParam String work) {
        ResponseEntity<Response<List<DraftVersion>>> denied = refuse(provided, "draft reads");
        if (denied != null) return denied;
        return ResponseEntity.ok(Response.ok(texts.versions(work)));
    }

    @GetMapping("/version/{id}/lines")
    public ResponseEntity<Response<List<DraftLine>>> lines(@RequestHeader(name = TOKEN_HEADER, required = false) String provided,
                                                            @PathVariable String id) {
        ResponseEntity<Response<List<DraftLine>>> denied = refuse(provided, "draft reads");
        if (denied != null) return denied;
        return ResponseEntity.ok(Response.ok(texts.lines(id)));
    }

    @PostMapping("/version/{id}/lines")
    public ResponseEntity<Response<Written>> addLine(@RequestHeader(name = TOKEN_HEADER, required = false) String provided,
                                                      @PathVariable String id, @RequestBody LineWrite body) {
        ResponseEntity<Response<Written>> denied = refuse(provided, "authoring");
        if (denied != null) return denied;
        return ok(texts.addLine(id, body));
    }

    @PutMapping("/line")
    public ResponseEntity<Response<Written>> updateLine(@RequestHeader(name = TOKEN_HEADER, required = false) String provided,
                                                         @RequestBody LineWrite body) {
        ResponseEntity<Response<Written>> denied = refuse(provided, "authoring");
        if (denied != null) return denied;
        return ok(texts.updateLine(body));
    }

    @PostMapping("/background")
    public ResponseEntity<Response<Written>> createBackground(@RequestHeader(name = TOKEN_HEADER, required = false) String provided,
                                                               @RequestBody BackgroundWrite body) {
        ResponseEntity<Response<Written>> denied = refuse(provided, "authoring");
        if (denied != null) return denied;
        return ok(texts.createBackground(body));
    }

    @PutMapping("/background/{id}")
    public ResponseEntity<Response<Written>> updateBackground(@RequestHeader(name = TOKEN_HEADER, required = false) String provided,
                                                               @PathVariable String id, @RequestBody BackgroundWrite body) {
        ResponseEntity<Response<Written>> denied = refuse(provided, "authoring");
        if (denied != null) return denied;
        return ok(texts.updateBackground(id, body));
    }

    @GetMapping("/backgrounds")
    public ResponseEntity<Response<List<DraftBackground>>> backgrounds(@RequestHeader(name = TOKEN_HEADER, required = false) String provided,
                                                                       @RequestParam String work) {
        ResponseEntity<Response<List<DraftBackground>>> denied = refuse(provided, "draft reads");
        if (denied != null) return denied;
        return ResponseEntity.ok(Response.ok(texts.backgrounds(work)));
    }

    @PostMapping("/background/{id}/lines")
    public ResponseEntity<Response<Written>> linkBackgroundLine(@RequestHeader(name = TOKEN_HEADER, required = false) String provided,
                                                                 @PathVariable String id, @RequestBody BackgroundLineWrite body) {
        ResponseEntity<Response<Written>> denied = refuse(provided, "authoring");
        if (denied != null) return denied;
        return ok(texts.linkBackgroundLine(new BackgroundLineWrite(id, body.versionId(), body.lineSeq())));
    }

    @GetMapping("/background/{id}/lines")
    public ResponseEntity<Response<List<DraftLine>>> backgroundLines(@RequestHeader(name = TOKEN_HEADER, required = false) String provided,
                                                                      @PathVariable String id) {
        ResponseEntity<Response<List<DraftLine>>> denied = refuse(provided, "draft reads");
        if (denied != null) return denied;
        return ResponseEntity.ok(Response.ok(texts.backgroundLines(id)));
    }

    @PostMapping("/annotation")
    public ResponseEntity<Response<Written>> createAnnotation(@RequestHeader(name = TOKEN_HEADER, required = false) String provided,
                                                               @RequestBody AnnotationWrite body) {
        ResponseEntity<Response<Written>> denied = refuse(provided, "authoring");
        if (denied != null) return denied;
        return ok(texts.createAnnotation(body));
    }

    @GetMapping("/annotations")
    public ResponseEntity<Response<List<DraftAnnotation>>> annotations(@RequestHeader(name = TOKEN_HEADER, required = false) String provided,
                                                                        @RequestParam String version) {
        ResponseEntity<Response<List<DraftAnnotation>>> denied = refuse(provided, "draft reads");
        if (denied != null) return denied;
        return ResponseEntity.ok(Response.ok(texts.annotations(version)));
    }

    @PostMapping("/relation")
    public ResponseEntity<Response<Written>> createRelation(@RequestHeader(name = TOKEN_HEADER, required = false) String provided,
                                                             @RequestBody RelationWrite body) {
        ResponseEntity<Response<Written>> denied = refuse(provided, "authoring");
        if (denied != null) return denied;
        return ok(texts.createRelation(body));
    }

    @GetMapping("/relations")
    public ResponseEntity<Response<List<DraftRelation>>> relations(@RequestHeader(name = TOKEN_HEADER, required = false) String provided,
                                                                    @RequestParam String subject) {
        ResponseEntity<Response<List<DraftRelation>>> denied = refuse(provided, "draft reads");
        if (denied != null) return denied;
        return ResponseEntity.ok(Response.ok(texts.relations(subject)));
    }

    @PostMapping("/work-author")
    public ResponseEntity<Response<Written>> attachWorkAuthor(@RequestHeader(name = TOKEN_HEADER, required = false) String provided,
                                                               @RequestBody WorkAuthorWrite body) {
        ResponseEntity<Response<Written>> denied = refuse(provided, "authoring");
        if (denied != null) return denied;
        return ok(texts.attachWorkAuthor(body));
    }

    @GetMapping("/work-authors")
    public ResponseEntity<Response<List<DraftWorkAuthor>>> authors(@RequestHeader(name = TOKEN_HEADER, required = false) String provided,
                                                                    @RequestParam String work) {
        ResponseEntity<Response<List<DraftWorkAuthor>>> denied = refuse(provided, "draft reads");
        if (denied != null) return denied;
        return ResponseEntity.ok(Response.ok(texts.authors(work)));
    }

    @PostMapping("/textbook")
    public ResponseEntity<Response<Written>> createTextbook(@RequestHeader(name = TOKEN_HEADER, required = false) String provided,
                                                             @RequestBody TextbookCreate body) {
        ResponseEntity<Response<Written>> denied = refuse(provided, "authoring");
        if (denied != null) return denied;
        return ok(texts.createTextbook(body));
    }

    @GetMapping("/textbooks")
    public ResponseEntity<Response<List<DraftTextbook>>> textbooks(@RequestHeader(name = TOKEN_HEADER, required = false) String provided) {
        ResponseEntity<Response<List<DraftTextbook>>> denied = refuse(provided, "draft reads");
        if (denied != null) return denied;
        return ResponseEntity.ok(Response.ok(texts.textbooks()));
    }

    @PostMapping("/textbook-work")
    public ResponseEntity<Response<Written>> attachTextbookWork(@RequestHeader(name = TOKEN_HEADER, required = false) String provided,
                                                                 @RequestBody TextbookWorkWrite body) {
        ResponseEntity<Response<Written>> denied = refuse(provided, "authoring");
        if (denied != null) return denied;
        return ok(texts.attachTextbookWork(body));
    }

    @GetMapping("/textbook-works")
    public ResponseEntity<Response<List<TextbookWorkWrite>>> textbookWorks(@RequestHeader(name = TOKEN_HEADER, required = false) String provided,
                                                                           @RequestParam String work) {
        ResponseEntity<Response<List<TextbookWorkWrite>>> denied = refuse(provided, "draft reads");
        if (denied != null) return denied;
        return ResponseEntity.ok(Response.ok(texts.textbookWorks(work)));
    }

    /**
     * Null means "allowed". A configured token is mandatory: an unauthenticated write path into the
     * real database is not acceptable even though the read side is deliberately public.
     */
    private <T> ResponseEntity<Response<T>> refuse(String provided, String what) {
        return PoetryGuards.refuse(TOKEN_HEADER, token, what, provided);
    }

    private static ResponseEntity<Response<Written>> ok(Written written) {
        return ResponseEntity.ok(Response.ok(written));
    }
}
