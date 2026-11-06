package com.timeline.poetry.api;

/** Authoring contracts. Everything here creates or edits DRAFT state; publishing is PoetryReviewService's job. */
public final class PoetryDraftModels {
    private PoetryDraftModels() {}

    public record ContentCreate(String id, String entityType, String slug, String title, String summary,
                                Integer startYear, Integer endYear, String timePrecision,
                                String dynastyId, String parentId, String placeId, String personId,
                                String eventId, String periodScope, String modernName, String courtesyName,
                                String genre) {}
    /** The poetry_content columns every entity shares; subtype-specific rows come from ContentCreate. */
    public record ContentCore(String id, String entityType, String slug, String title, String summary,
                              Integer startYear, Integer endYear, String timePrecision) {}
    public record ContentUpdate(String title, String summary, Integer startYear, Integer endYear, String timePrecision) {}
    public record SourceCreate(String id, String title, String author, String edition, String url,
                               String rightsNote, String sourceKind, String reliability) {}
    public record SourceUpdate(String title, String edition, String url, String rightsNote,
                               String sourceKind, String reliability) {}
    public record ClaimCreate(String id, String subjectId, String propertyKey, String valueText,
                              String claimKind, String certainty) {}
    public record ClaimUpdate(String valueText, String certainty) {}
    public record CitationCreate(String claimId, String sourceId, String locator, String evidenceExcerpt) {}
    public record Adoption(String subjectId, String propertyKey, String claimId) {}
    public record CoverageWrite(String id, String entityType, Integer fromYear, Integer toYear,
                                String coverageKind, String status, String note, String updatedBy) {}

    public record DraftContent(String id, String entityType, String slug, String title, String summary,
                               Integer startYear, Integer endYear, String timePrecision, String status,
                               Integer revision, String reviewedBy) {}
    public record DraftSource(String id, String title, String author, String edition, String url,
                              String rightsNote, String sourceKind, String reliability,
                              String verificationStatus) {}
    public record DraftClaim(String id, String subjectId, String propertyKey, String valueText, String claimKind,
                             String certainty, String status) {}
    public record DraftCitation(String claimId, String sourceId, String locator, String evidenceExcerpt,
                                String verificationStatus) {}
    public record DraftSelection(String subjectId, String propertyKey, String claimId) {}
    public record DraftCoverage(String id, String entityType, Integer fromYear, Integer toYear,
                                String coverageKind, String status, String note) {}


    // ---------- slice 2: text versions, lines, backgrounds, annotations, relations, authorship, textbooks ----------
    public record VersionCreate(String id, String workId, String versionCode, String label,
                                String script, String sourceId, String sourceLocator) {}
    public record VersionUpdate(String label, String sourceId, String sourceLocator) {}
    public record LineWrite(String versionId, Integer lineSeq, String content, String pinyin) {}
    /** Background + its own claim (+ optional citation) as one atomic authoring act: background.claim_id is NOT NULL. */
    public record BackgroundWrite(String id, String workId, String title, String layer, String audience, String bodyText,
                                  String claimId, String claimValue, String claimKind, String certainty,
                                  String sourceId, String locator) {}
    public record BackgroundLineWrite(String backgroundId, String versionId, Integer lineSeq) {}
    public record AnnotationWrite(String id, String versionId, Integer lineSeq, String annotationKind,
                                  String audience, String content, String claimId, String claimValue,
                                  String certainty, String sourceId, String locator) {}
    public record RelationWrite(String id, String subjectId, String predicate, String objectId,
                                String claimId, String claimValue, String certainty,
                                String sourceId, String locator) {}
    public record WorkAuthorWrite(String workId, String personId, String attribution,
                                  String claimId, String claimValue, String certainty) {}
    public record TextbookCreate(String id, String title, String publisher, String edition,
                                 String schoolStage, Integer gradeNo, String volume, String isbn) {}
    public record TextbookWorkWrite(String textbookId, String workId, String versionId,
                                    String unitLabel, String lessonLabel, String pageLocator) {}

    public record DraftVersion(String id, String workId, String versionCode, String label, String script,
                               String sourceId, String sourceLocator, String status) {}
    public record DraftLine(String versionId, Integer lineSeq, String content, String pinyin) {}
    public record DraftBackground(String id, String workId, String layer, String audience, String bodyText,
                                  String claimId) {}
    public record DraftAnnotation(String id, String versionId, Integer lineSeq, String annotationKind,
                                  String audience, String content, String claimId) {}
    public record DraftRelation(String id, String subjectId, String predicate, String objectId, String claimId) {}
    public record DraftWorkAuthor(String workId, String personId, String attribution, String claimId) {}
    public record DraftTextbook(String id, String title, String publisher, String edition, String schoolStage,
                                Integer gradeNo, String volume, String isbn, String verificationStatus) {}

    /** Result of any write: what happened, what the operator should still do, and whether the library is clean. */
    public record Written(String subject, boolean applied, java.util.List<String> notices,
                          int auditChecks, java.util.List<String> auditNonZero) {}
}
