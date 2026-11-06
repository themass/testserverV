package com.timeline.poetry.service;

import com.timeline.poetry.api.PoetryModels.*;
import com.timeline.poetry.domain.TimeSpan;
import com.timeline.poetry.domain.Vocabulary;
import com.timeline.poetry.persistence.PoetryMapper;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;
import java.util.List;
import java.util.Locale;
import java.util.Set;

public class PoetryCatalog {
    private static final Set<String> TYPES = Vocabulary.ENTITY_TYPES;
    private static final String COVERAGE_NOTICE = "仅展示当前已发布且有年代范围的内容；空白代表尚未覆盖，不代表历史上不存在。年代不可考的内容请通过目录查询。";
    private static final int COVERAGE_ROWS = 50;
    private final PoetryMapper mapper;
    public PoetryCatalog(PoetryMapper mapper) { this.mapper = mapper; }
    public static void pageBounds(int limit, int offset) {
        if (limit < 1 || limit > 100 || offset < 0 || offset > 1_000_000)
            throw new BadRequest("limit must be 1..100; offset must be 0..1000000");
    }
    private String type(String type) {
        if (type == null) return null;
        String normalized = type.toUpperCase(Locale.ROOT);
        if (!TYPES.contains(normalized)) throw new BadRequest("Invalid content type");
        return normalized;
    }
    public ContentItem content(String id, String expectedType) {
        if (id == null || !id.matches("[A-Za-z0-9][A-Za-z0-9_-]{0,63}"))
            throw new BadRequest("Invalid content id");
        ContentItem item = mapper.content(id);
        if (item == null || (expectedType != null && !expectedType.equals(item.entityType())))
            throw new NotFound();
        return item;
    }
    public Page<ContentItem> contents(String type, int limit, int offset) {
        pageBounds(limit, offset);
        return Page.from(mapper.contents(type(type), limit + 1, offset), limit, offset);
    }
    public Timeline timeline(String type, int from, int to, int limit, int offset) {
        pageBounds(limit, offset);
        try {
            new TimeSpan(from, to, "RANGE");
        } catch (IllegalArgumentException ex) {
            throw new BadRequest(ex.getMessage());
        }
        if (from < -9999 || to > 9999 || (long) to - from > 5000)
            throw new BadRequest("Timeline bounds must be within -9999..9999 and span at most 5000 years");
        // An empty coverage list is itself the answer: nothing is declared covered yet.
        return new Timeline(Page.from(mapper.timeline(type(type), from, to, limit + 1, offset), limit, offset),
            List.copyOf(mapper.coverages(type(type), COVERAGE_ROWS, 0)), false, COVERAGE_NOTICE);
    }
    public WorkDetail work(String id) {
        ContentItem content = content(id, "WORK");
        WorkInfo work = mapper.work(id);
        if (work == null) throw new NotFound();
        return new WorkDetail(content, work);
    }
    public Page<ContentItem> experiences(String id, int limit, int offset) {
        pageBounds(limit, offset); content(id, "PERSON");
        return Page.from(mapper.experiences(id, limit + 1, offset), limit, offset);
    }
    public Page<TextVersion> versions(String id, int limit, int offset) {
        pageBounds(limit, offset); work(id);
        return Page.from(mapper.versions(id, limit + 1, offset), limit, offset);
    }
    public Page<TextLine> lines(String id, int limit, int offset) {
        pageBounds(limit, offset);
        if (mapper.version(id) == null) throw new NotFound();
        return Page.from(mapper.lines(id, limit + 1, offset), limit, offset);
    }
    public Page<Claim> claims(String id, int limit, int offset) {
        pageBounds(limit, offset); content(id, null);
        return Page.from(mapper.claims(id, limit + 1, offset), limit, offset);
    }
    public Claim claim(String id) {
        Claim claim = mapper.claim(id);
        if (claim == null) throw new NotFound();
        return claim;
    }
    public Page<Citation> citations(String id, int limit, int offset) {
        pageBounds(limit, offset); claim(id);
        return Page.from(mapper.citations(id, limit + 1, offset), limit, offset);
    }
    public Page<Relation> relations(String id, int limit, int offset) {
        pageBounds(limit, offset); content(id, null);
        return Page.from(mapper.relations(id, limit + 1, offset), limit, offset);
    }
    public Page<Author> authors(String id, int limit, int offset) {
        pageBounds(limit, offset); work(id);
        return Page.from(mapper.authors(id, limit + 1, offset), limit, offset);
    }
    public Page<Background> backgrounds(String id, int limit, int offset) {
        pageBounds(limit, offset); work(id);
        return Page.from(mapper.backgrounds(id, limit + 1, offset), limit, offset);
    }
    public List<Coverage> coverage(String type) {
        return List.copyOf(mapper.coverages(type(type), COVERAGE_ROWS, 0));
    }
    public Page<ThemeItem> themeItems(String id, int limit, int offset) {
        pageBounds(limit, offset); content(id, "THEME");
        // Theme membership is only readable when the theme itself and every item are published.
        return Page.from(mapper.themeItems(id, limit + 1, offset), limit, offset);
    }
    public Page<BackgroundLine> backgroundLines(String id, int limit, int offset) {
        pageBounds(limit, offset); content(id, "BACKGROUND");
        // Parent/claim/text publication is rechecked by the mapper, never trusted from a prior request.
        return Page.from(mapper.backgroundLines(id, limit + 1, offset), limit, offset);
    }
    /** Missing or unpublished public content. Not a subclass of IllegalArgumentException. */
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public static class NotFound extends RuntimeException {
        public NotFound() { super("Content not found"); }
    }
    /** Invalid client parameters. Kept separate from IllegalArgumentException so 404 is never remapped to 400. */
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public static class BadRequest extends RuntimeException {
        public BadRequest(String message) { super(message); }
    }
}
