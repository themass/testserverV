package com.timeline.student.api;

import com.timeline.poetry.api.PoetryModels.Coverage;
import com.timeline.poetry.api.PoetryModels.Page;
import com.timeline.poetry.api.PoetryModels.ContentItem;
import java.util.List;

/** Wire shapes of /api/student/v1. Records only; no entity leaks from the poetry module's persistence layer. */
public final class StudentModels {
    private StudentModels() {}

    /** Same envelope as vvv-poetry so the front end has one error path. */
    public record Response<T>(int errno, T data, String error) {
        public static <T> Response<T> ok(T data) { return new Response<>(0, data, null); }
    }

    /* ---------- config ---------- */
    /** No grade/audience: one telling for every reader (product decision 2026-11-12). */
    public record Config(String assetBase, int minSchemaMajor, String dataNoticeVersion, boolean agentEnabled) {}

    /* ---------- content ---------- */
    /** The newest PUBLISHED script of a work that actually has a compiled bundle. */
    public record LessonEntry(String scriptId, String scriptVersion, String schemaVersion, String workId,
                              String textVersionId, String bundleHash, String coverageNotice) {}
    public record WorkCard(String workId, String title, String summary, Integer startYear, Integer endYear,
                           String timePrecision, boolean hasLesson) {}
    public record Author(String personId, String name, String attribution) {}
    public record Line(int seq, String text, String pinyin) {}
    public record AnnotationItem(String id, int lineSeq, String kind, String text) {}
    /** claimKind/certainty come from the claim behind the text, so the page can show 史实/理解/演绎 without guessing. */
    /** One per layer: the reader is not split by grade, so the server picks the single text to show. */
    public record BackgroundItem(String id, String layer, String body, String claimId,
                                 String claimKind, String certainty) {}
    /** What a learner may see of a source: enough to find it again, nothing about rights or internal ids. */
    public record CitationItem(String title, String author, String edition, String locator, String evidenceExcerpt) {}
    public record Relation(String backgroundId, int lineSeq) {}
    /** certainty/selected come from the claim, so a disputed date is shown as disputed, never silently chosen. */
    public record DateClaim(String claimId, String propertyKey, String text, String certainty, boolean selected) {}
    public record Pack(String workId, String title, List<Author> authors, String textVersionId, List<Line> lines,
                       List<AnnotationItem> annotations, List<BackgroundItem> backgrounds, List<Relation> relations,
                       List<DateClaim> writtenAt, String coverageNotice, List<String> warnings) {}

    public record TimelineView(Page<ContentItem> results, List<Coverage> coverage, boolean includesUnknownDates,
                               String coverageNotice, List<String> lessonWorkIds) {}

    /** "全貌" (overview) is composed from published items only; an empty list means "not covered yet". */
    public record Overview(List<ContentItem> dynasties, List<ContentItem> people, List<ContentItem> works,
                           List<ThemeLine> themes, List<Coverage> coverage, String coverageNotice,
                           List<String> lessonWorkIds) {}
    public record ThemeLine(String themeId, String title, List<ThemeMember> members) {}
    public record ThemeMember(String itemId, String title, String itemType, Integer startYear, Integer endYear,
                              String role) {}

    /* ---------- assets (read-only registry of PUBLISHED rows) ---------- */
    public record AssetRow(String id, String kind, String level, String uri, String hash, Long bytes,
                           String fallbackId, String meaning, String rightsOrigin, String rightsLicense) {}
    public record ChainLink(String assetId, String level, String hash) {}
    public record AssetChain(String assetId, List<ChainLink> chain, boolean reachesText, boolean loop) {}

    /* ---------- devices & learning records ---------- */
    /** The key is returned exactly once. Only its SHA-256 is stored. */
    public record DeviceCreated(String deviceId, String deviceKey, String dataNoticeVersion) {}
    public record DeviceInfo(String deviceId, String createdAt, String dataNoticeVersion) {}
    public record SessionWrite(String lastStep, List<String> visited) {}
    public record SessionView(String workId, String lastStep, List<String> visited,
                              String enteredAt, String updatedAt) {}
    public record EventIn(String workId, String step, String kind, String ref, Integer ms, String at) {}
    public record GapIn(String workId, String scriptHash, List<String> covered, List<String> missing) {}
    public record Accepted(int accepted) {}

    public record BoardPoint(String pointId, int coveredDevices, int missingDevices) {}
    public record Board(String workId, String scriptHash, boolean enoughData, int devices, List<BoardPoint> points) {}
}
