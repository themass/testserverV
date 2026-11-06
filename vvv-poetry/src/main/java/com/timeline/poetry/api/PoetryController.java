package com.timeline.poetry.api;

import com.timeline.poetry.api.PoetryModels.*;
import com.timeline.poetry.service.PoetryCatalog;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import java.util.List;

@RestController
@RequestMapping("/api/poetry/v1")
public class PoetryController {
    private final PoetryCatalog catalog;
    public PoetryController(PoetryCatalog catalog) { this.catalog = catalog; }
    @GetMapping("/content")
    public Response<Page<ContentItem>> contents(@RequestParam(required=false) String type, @RequestParam(defaultValue="20") int limit,
                                                   @RequestParam(defaultValue="0") int offset) {
        return Response.ok(catalog.contents(type, limit, offset));
    }
    @GetMapping("/timeline")
    public Response<Timeline> timeline(@RequestParam(required=false) String type, @RequestParam int fromYear, @RequestParam int toYear, @RequestParam(defaultValue="20") int limit,
                                                   @RequestParam(defaultValue="0") int offset) {
        return Response.ok(catalog.timeline(type, fromYear, toYear, limit, offset));
    }
    @GetMapping("/persons/{id}/experiences")
    public Response<Page<ContentItem>> experiences(@PathVariable String id, @RequestParam(defaultValue="20") int limit,
                                                   @RequestParam(defaultValue="0") int offset) {
        return Response.ok(catalog.experiences(id, limit, offset));
    }
    @GetMapping("/works/{id}/versions")
    public Response<Page<TextVersion>> versions(@PathVariable String id, @RequestParam(defaultValue="20") int limit,
                                                   @RequestParam(defaultValue="0") int offset) {
        return Response.ok(catalog.versions(id, limit, offset));
    }
    @GetMapping("/versions/{id}/lines")
    public Response<Page<TextLine>> lines(@PathVariable String id, @RequestParam(defaultValue="20") int limit,
                                                   @RequestParam(defaultValue="0") int offset) {
        return Response.ok(catalog.lines(id, limit, offset));
    }
    @GetMapping("/content/{id}/claims")
    public Response<Page<Claim>> claims(@PathVariable String id, @RequestParam(defaultValue="20") int limit,
                                                   @RequestParam(defaultValue="0") int offset) {
        return Response.ok(catalog.claims(id, limit, offset));
    }
    @GetMapping("/claims/{id}/citations")
    public Response<Page<Citation>> citations(@PathVariable String id, @RequestParam(defaultValue="20") int limit,
                                                   @RequestParam(defaultValue="0") int offset) {
        return Response.ok(catalog.citations(id, limit, offset));
    }
    @GetMapping("/content/{id}/relations")
    public Response<Page<Relation>> relations(@PathVariable String id, @RequestParam(defaultValue="20") int limit,
                                                   @RequestParam(defaultValue="0") int offset) {
        return Response.ok(catalog.relations(id, limit, offset));
    }
    @GetMapping("/works/{id}/authors")
    public Response<Page<Author>> authors(@PathVariable String id, @RequestParam(defaultValue="20") int limit,
                                                   @RequestParam(defaultValue="0") int offset) {
        return Response.ok(catalog.authors(id, limit, offset));
    }
    @GetMapping("/works/{id}/backgrounds")
    public Response<Page<Background>> backgrounds(@PathVariable String id, @RequestParam(defaultValue="20") int limit,
                                                   @RequestParam(defaultValue="0") int offset) {
        return Response.ok(catalog.backgrounds(id, limit, offset));
    }
    @GetMapping("/coverage")
    public Response<List<Coverage>> coverage(@RequestParam(required=false) String type) {
        return Response.ok(catalog.coverage(type));
    }
    @GetMapping("/themes/{id}/items")
    public Response<Page<ThemeItem>> themeItems(@PathVariable String id, @RequestParam(defaultValue="20") int limit,
                                                   @RequestParam(defaultValue="0") int offset) {
        return Response.ok(catalog.themeItems(id, limit, offset));
    }
    @GetMapping("/backgrounds/{id}/lines")
    public Response<Page<BackgroundLine>> backgroundLines(@PathVariable String id, @RequestParam(defaultValue="20") int limit,
                                                   @RequestParam(defaultValue="0") int offset) {
        return Response.ok(catalog.backgroundLines(id, limit, offset));
    }
    @GetMapping("/content/{id}")
    public Response<ContentItem> content(@PathVariable String id) { return Response.ok(catalog.content(id, null)); }
    @GetMapping("/works/{id}")
    public Response<WorkDetail> work(@PathVariable String id) { return Response.ok(catalog.work(id)); }
    @GetMapping("/claims/{id}")
    public Response<Claim> claim(@PathVariable String id) { return Response.ok(catalog.claim(id)); }

    @ExceptionHandler(PoetryCatalog.NotFound.class)
    public ResponseEntity<Response<Void>> notFound(PoetryCatalog.NotFound exception) {
        return ResponseEntity.status(404).body(new Response<>(404, null, "Content not found"));
    }
    // Do not catch IllegalArgumentException: if NotFound were ever a subclass it would be remapped to 400.
    @ExceptionHandler({PoetryCatalog.BadRequest.class, MissingServletRequestParameterException.class,
                       MethodArgumentTypeMismatchException.class})
    public ResponseEntity<Response<Void>> badRequest(Exception exception) {
        return ResponseEntity.badRequest().body(new Response<>(400, null, "Invalid request parameters"));
    }
}
