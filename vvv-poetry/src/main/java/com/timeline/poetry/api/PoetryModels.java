package com.timeline.poetry.api;

import java.util.List;

public final class PoetryModels {
    private PoetryModels() {}
    public record ContentItem(String id, String entityType, String slug, String title, String summary,
                              Integer startYear, Integer endYear, String timePrecision, Integer revision) {}
    public record WorkInfo(String id, String genre, String dynastyId, String creationPlaceId) {}
    public record WorkDetail(ContentItem content, WorkInfo work) {}
    public record TextVersion(String id, String workId, String versionCode, String label, String script,
                              String sourceId, String sourceLocator) {}
    public record TextLine(String versionId, Integer lineSeq, String content, String pinyin) {}
    public record Claim(String id, String subjectId, String propertyKey, String valueText, String claimKind,
                        String certainty, Boolean dramatizationLabeled, Boolean selected) {}
    public record Citation(String sourceId, String title, String author, String edition, String url,
                           String rightsNote, String locator, String evidenceExcerpt) {}
    public record Relation(String id, String predicate, String objectId, String objectTitle, String claimId) {}
    /** One background = one layer (SCENE/CITY/WORLD/PERSON) + one body text (V003 rule). */
    public record Background(String id, String title, String layer, String audience, String bodyText,
                             String claimId) {}
    public record Coverage(String id, String entityType, Integer fromYear, Integer toYear,
                           String coverageKind, String note) {}
    public record ThemeItem(String themeId, Integer ordinal, String itemRole, String itemId, String slug,
                            String title, String itemType, Integer startYear, Integer endYear,
                            String timePrecision) {}
    public record BackgroundLine(String versionId, Integer lineSeq) {}
    public record Author(String personId, String name, String attribution, String claimId) {}
    public record Page<T>(List<T> items, int limit, int offset, boolean hasMore) {
        public static <T> Page<T> from(List<T> fetched, int limit, int offset) {
            boolean more = fetched.size() > limit;
            return new Page<>(List.copyOf(fetched.subList(0, Math.min(limit, fetched.size()))), limit, offset, more);
        }
    }
    /** coverage comes from poetry_coverage rows, not from a string baked into Java. */
    public record Timeline(Page<ContentItem> results, List<Coverage> coverage, boolean includesUnknownDates,
                           String coverageNotice) {}
    /** Plain JSON. Intentionally independent of legacy JsonResult's DevApp/AES context. */
    public record Response<T>(int errno, T data, String error) {
        public static <T> Response<T> ok(T data) { return new Response<>(0, data, null); }
    }
}
