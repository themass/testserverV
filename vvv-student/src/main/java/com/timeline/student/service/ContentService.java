package com.timeline.student.service;

import com.timeline.poetry.api.PoetryModels.Background;
import com.timeline.poetry.api.PoetryModels.BackgroundLine;
import com.timeline.poetry.api.PoetryModels.Claim;
import com.timeline.poetry.api.PoetryModels.ContentItem;
import com.timeline.poetry.api.PoetryModels.Page;
import com.timeline.poetry.api.PoetryModels.TextLine;
import com.timeline.poetry.api.PoetryModels.TextVersion;
import com.timeline.poetry.api.PoetryModels.ThemeItem;
import com.timeline.poetry.api.PoetryModels.Timeline;
import com.timeline.poetry.service.PoetryCatalog;
import com.timeline.student.api.StudentModels.*;
import com.timeline.student.domain.StudentErrors.BadRequest;
import com.timeline.student.domain.StudentErrors.NotFound;
import com.timeline.student.persistence.StudentContentMapper;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import static com.timeline.student.domain.StudentVocabulary.BUNDLE_HASH;
import static com.timeline.student.domain.StudentVocabulary.ID;

/**
 * Published-only content for the student app. Everything that comes from the content base goes through
 * PoetryCatalog (the one implementation of the publish gate) or a StudentContentMapper query that carries
 * its own PUBLISHED conditions. There is no code path here that reads a DRAFT row.
 *
 * Unreadable parts degrade to empty + a warning. They are never filled from anywhere else.
 */
public class ContentService {
    static final String DEFAULT_COVERAGE =
        "本轮只整理了部分内容；没有出现在这里的，只代表当前还没有收录，不代表历史上没有。";
    private static final int PAGE = 100;
    private static final int MAX_LINES = 64;
    private static final int MAX_THEMES = 12;

    private final PoetryCatalog catalog;
    private final StudentContentMapper mapper;
    private final BundleStore bundles;

    public ContentService(PoetryCatalog catalog, StudentContentMapper mapper, BundleStore bundles) {
        this.catalog = catalog; this.mapper = mapper; this.bundles = bundles;
    }

    /* ---------- timeline & overview ---------- */

    public TimelineView timeline(String type, int from, int to, int limit, int offset) {
        Timeline t = catalog.timeline(type, from, to, limit, offset);
        return new TimelineView(t.results(), t.coverage(), t.includesUnknownDates(), t.coverageNotice(), mapper.lessonWorkIds());
    }

    public Overview overview() {
        List<String> warnings = new ArrayList<>();
        List<ContentItem> dynasties = safe(() -> catalog.contents("DYNASTY", PAGE, 0).items(), warnings);
        List<ContentItem> people = safe(() -> catalog.contents("PERSON", PAGE, 0).items(), warnings);
        List<ContentItem> works = safe(() -> catalog.contents("WORK", PAGE, 0).items(), warnings);
        List<ContentItem> themes = safe(() -> catalog.contents("THEME", MAX_THEMES, 0).items(), warnings);
        List<ThemeLine> lines = new ArrayList<>();
        for (ContentItem theme : themes) {
            List<ThemeItem> items = safe(() -> catalog.themeItems(theme.id(), PAGE, 0).items(), warnings);
            lines.add(new ThemeLine(theme.id(), theme.title(), items.stream().map(i -> new ThemeMember(
                i.itemId(), i.title(), i.itemType(), i.startYear(), i.endYear(), i.itemRole())).toList()));
        }
        String notice = DEFAULT_COVERAGE;
        List<com.timeline.poetry.api.PoetryModels.Coverage> coverage = catalog.coverage(null);
        return new Overview(dynasties, people, works, lines, coverage, notice, mapper.lessonWorkIds());
    }

    /* ---------- works ---------- */

    public List<WorkCard> works() {
        Set<String> withLesson = Set.copyOf(mapper.lessonWorkIds());
        return catalog.contents("WORK", PAGE, 0).items().stream().map(c -> new WorkCard(c.id(), c.title(),
            c.summary(), c.startYear(), c.endYear(), c.timePrecision(), withLesson.contains(c.id()))).toList();
    }

    public WorkCard work(String workId) {
        ContentItem c = catalog.work(workId).content();
        return new WorkCard(c.id(), c.title(), c.summary(), c.startYear(), c.endYear(), c.timePrecision(),
            mapper.latestLesson(c.id()) != null);
    }

    /** 404 when no published, compiled script exists: the student app then shows "场景整理中". */
    public LessonEntry lesson(String workId) {
        checkId(workId);
        catalog.work(workId);                       // published work, or NotFound
        LessonEntry entry = mapper.latestLesson(workId);
        if (entry == null) throw new NotFound("no published lesson for this work");
        return entry;
    }

    public Pack pack(String workId) {
        checkId(workId);
        var detail = catalog.work(workId);          // published work, or NotFound
        List<String> warnings = new ArrayList<>();

        // Prefer the exact text version the published script was compiled against; else the first published one.
        LessonEntry lesson = mapper.latestLesson(workId);
        TextVersion version = null;
        List<TextVersion> versions = catalog.versions(workId, PAGE, 0).items();
        if (lesson != null) {
            for (TextVersion v : versions) if (v.id().equals(lesson.textVersionId())) { version = v; break; }
        }
        if (version == null && !versions.isEmpty()) version = versions.get(0);
        if (version == null) throw new NotFound("no published text version");   // sample spec 8.2: not fully published -> 404

        final String versionId = version.id();
        List<Line> lines = new ArrayList<>();
        for (int offset = 0; offset < MAX_LINES; offset += PAGE) {
            Page<TextLine> page = catalog.lines(versionId, PAGE, offset);
            for (TextLine l : page.items()) if (lines.size() < MAX_LINES) lines.add(new Line(l.lineSeq(), l.content(), l.pinyin()));
            if (!page.hasMore()) break;
        }
        if (lines.isEmpty()) throw new NotFound("no published lines");

        List<AnnotationItem> annotations = safe(() -> mapper.annotations(versionId), warnings);
        if (annotations.isEmpty()) warnings.add("annotations: none published");

        List<Background> bgs = oneTextPerLayer(safe(() -> catalog.backgrounds(workId, PAGE, 0).items(), warnings));
        List<BackgroundItem> backgrounds = new ArrayList<>();
        List<Relation> relations = new ArrayList<>();
        for (Background b : bgs) {
            // The claim behind a background says whether the text is 史实 / 理解 / 演绎 and how sure we are.
            Claim backing = claimOrNull(b.claimId());
            backgrounds.add(new BackgroundItem(b.id(), b.layer(), b.bodyText(), b.claimId(),
                backing == null ? null : backing.claimKind(), backing == null ? null : backing.certainty()));
            for (BackgroundLine bl : safe(() -> catalog.backgroundLines(b.id(), PAGE, 0).items(), warnings))
                if (versionId.equals(bl.versionId())) relations.add(new Relation(b.id(), bl.lineSeq()));
        }

        List<Author> authors = safe(() -> catalog.authors(workId, 10, 0).items().stream()
            .map(a -> new Author(a.personId(), a.name(), a.attribution())).toList(), warnings);

        List<DateClaim> written = new ArrayList<>();
        for (Claim c : safe(() -> catalog.claims(workId, PAGE, 0).items(), warnings))
            if (c.propertyKey() != null && c.propertyKey().startsWith("time."))
                written.add(new DateClaim(c.id(), c.propertyKey(), c.valueText(), c.certainty(), Boolean.TRUE.equals(c.selected())));

        String notice = lesson != null && lesson.coverageNotice() != null && !lesson.coverageNotice().isBlank()
            ? lesson.coverageNotice() : DEFAULT_COVERAGE;
        return new Pack(workId, detail.content().title(), authors, versionId, lines, annotations, backgrounds,
            relations, written, notice, warnings);
    }

    /* ---------- bundles ---------- */

    /** Served only if a PUBLISHED script row carries exactly this hash AND the file exists AND its manifest agrees. */
    public byte[] bundle(String hash) {
        requirePublishedBundle(hash);
        return bundles.bundle(hash);
    }

    public byte[] manifest(String hash) {
        requirePublishedBundle(hash);
        return bundles.manifest(hash);
    }

    private void requirePublishedBundle(String hash) {
        if (hash == null || !BUNDLE_HASH.matcher(hash).matches()) throw new NotFound("bundle not found");
        if (mapper.publishedBundleCount(hash) < 1) throw new NotFound("bundle not found");
    }

    /* ---------- citations ---------- */

    /** Published claim only (PoetryCatalog.claim answers NotFound otherwise); then its verified sources. */
    public List<CitationItem> citations(String claimId) {
        checkId(claimId);
        catalog.claim(claimId);
        return catalog.citations(claimId, PAGE, 0).items().stream()
            .map(c -> new CitationItem(c.title(), c.author(), c.edition(), c.locator(), c.evidenceExcerpt())).toList();
    }

    private Claim claimOrNull(String claimId) {
        if (claimId == null || !ID.matcher(claimId).matches()) return null;
        try { return catalog.claim(claimId); } catch (RuntimeException ex) { return null; }
    }

    /* ---------- assets ---------- */

    public List<AssetRow> assets(String level, int limit, int offset) {
        if (limit < 1 || limit > 200 || offset < 0 || offset > 100_000) throw new BadRequest("limit must be 1..200");
        if (level != null && !Set.of("L0", "L1", "L1.5", "L2", "L3", "L4").contains(level)) throw new BadRequest("level");
        return mapper.assets(level, limit, offset);
    }

    public AssetChain chain(String assetId) {
        checkId(assetId);
        List<ChainLink> chain = new ArrayList<>();
        java.util.Set<String> seen = new java.util.HashSet<>();
        AssetRow cursor = mapper.asset(assetId);
        if (cursor == null) throw new NotFound("asset not found");
        boolean loop = false;
        while (cursor != null && chain.size() < 12) {
            if (!seen.add(cursor.id())) { loop = true; break; }
            chain.add(new ChainLink(cursor.id(), cursor.level(), cursor.hash()));
            cursor = cursor.fallbackId() == null ? null : mapper.asset(cursor.fallbackId());
        }
        boolean reachesText = !chain.isEmpty() && "L0".equals(chain.get(chain.size() - 1).level());
        return new AssetChain(assetId, chain, reachesText, loop);
    }

    /* ---------- helpers ---------- */

    private static void checkId(String id) {
        if (id == null || !ID.matcher(id).matches()) throw new BadRequest("invalid id");
    }

    private interface Reader<T> { T get(); }

    /** A failing sub-read becomes "empty + warning". Never swallowed silently, never substituted. */
    private static <T> List<T> safe(Reader<List<T>> reader, List<String> warnings) {
        try {
            return reader.get();
        } catch (PoetryCatalog.NotFound ex) {
            return List.of();
        } catch (RuntimeException ex) {
            warnings.add("a part could not be read: " + ex.getClass().getSimpleName());
            return List.of();
        }
    }

    /**
     * The reader is not split by grade (2026-11-12): every layer shows one text. Content written before that
     * decision can still carry per-grade variants in {@code poetry_background.audience}; pick one per layer,
     * preferring a variant written for no particular grade, then the fuller (non-PRIMARY) one. Layer order is
     * the order the catalog returned. New content should simply not write variants.
     */
    static List<Background> oneTextPerLayer(List<Background> all) {
        java.util.LinkedHashMap<String, Background> chosen = new java.util.LinkedHashMap<>();
        for (Background b : all) {
            Background current = chosen.get(b.layer());
            if (current == null || rank(b) < rank(current)) chosen.put(b.layer(), b);
        }
        return new ArrayList<>(chosen.values());
    }

    private static int rank(Background b) {
        String a = b.audience();
        if (a == null || a.isBlank()) return 0;
        return "PRIMARY".equals(a) ? 2 : 1;
    }
}
