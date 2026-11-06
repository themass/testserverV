package com.timeline.poetry.service;

import com.timeline.poetry.api.PoetryDraftModels.*;
import com.timeline.poetry.domain.TimeSpan;
import com.timeline.poetry.domain.Vocabulary;
import com.timeline.poetry.persistence.PoetryDraftWriter;
import org.springframework.transaction.annotation.Transactional;
import java.util.ArrayList;
import java.util.List;

/**
 * Authoring service for the base information tables.
 *
 * With FOREIGN KEY forbidden, this class is where referential integrity actually lives:
 * every referenced id is checked before the insert, ids and vocabularies are validated, and
 * the whole write is followed by the 106 audit checks on the same transaction. A write that
 * would leave the library dirty is rolled back, so "no foreign keys" never means "anything goes".
 * Nothing here can make content visible: creation always lands in DRAFT.
 */
public class PoetryDraftService {
    private static final String ID_PATTERN = "[A-Za-z][A-Za-z0-9_-]{1,63}";
    private static final List<String> HANDLED_TYPES =
        List.of("DYNASTY", "PERIOD", "PLACE", "PERSON", "EVENT", "EXPERIENCE", "WORK", "THEME");

    private final PoetryDraftWriter writer;
    private final AuditRunner audit;

    public PoetryDraftService(PoetryDraftWriter writer, AuditRunner audit) { this.writer = writer; this.audit = audit; }

    /** Rejected request: bad vocabulary, missing reference, duplicate id/slug. Never mutates. */
    public static class Invalid extends RuntimeException {
        public Invalid(String message) { super(message); }
    }
    /** The write would leave the library unverified-clean; the transaction is rolled back. */
    public static class Dirty extends RuntimeException {
        public Dirty(String message) { super(message); }
    }

    @Transactional
    public Written createContent(ContentCreate c) {
        List<String> notices = new ArrayList<>();
        id(c.id());
        String type = c.entityType() == null ? "" : c.entityType().toUpperCase(java.util.Locale.ROOT);
        if (!HANDLED_TYPES.contains(type))
            throw new Invalid("entity_type not handled by this endpoint: " + c.entityType()
                + " (supported: " + String.join("/", HANDLED_TYPES) + ")");
        if (c.slug() == null || c.slug().isBlank() || c.title() == null || c.title().isBlank())
            throw new Invalid("slug and title are required");
        if (orZero(writer.existsContent(c.id())) > 0) throw new Invalid("id already exists: " + c.id());
        if (orZero(writer.countSlug(type, c.slug())) > 0)
            throw new Invalid("slug already used for this entity_type: " + type + "/" + c.slug());
        String precision = c.timePrecision() == null ? "UNKNOWN" : c.timePrecision();
        try { new TimeSpan(c.startYear(), c.endYear(), precision); }
        catch (IllegalArgumentException ex) { throw new Invalid(ex.getMessage()); }
        requireReferences(type, c);
        if (c.startYear() != null
            && orZero(writer.countClaims(c.id(), "time.span")) == 0)
            notices.add("年代已填但还缺 property_key='time.span' 的 FACT claim + 采用说；发布时 C6 会拦。");

        writer.insertContent(new ContentCore(c.id(), type, c.slug().trim(), c.title().trim(), c.summary(),
            c.startYear(), c.endYear(), precision));
        switch (type) {
            case "DYNASTY" -> writer.insertDynasty(c.id());
            case "PERIOD" -> writer.insertPeriod(c);
            case "PLACE" -> writer.insertPlace(c);
            case "PERSON" -> writer.insertPerson(c);
            case "EVENT" -> writer.insertEvent(c);
            case "EXPERIENCE" -> writer.insertExperience(c);
            case "WORK" -> writer.insertWork(c);
            default -> writer.insertTheme(c);
        }
        return done("poetry_content/" + c.id(), notices);
    }

    @Transactional
    public Written updateContent(String id, ContentUpdate u) {
        id(id);
        DraftContent current = writer.draftContent(id);
        if (current == null) throw new Invalid("content not found: " + id);
        if (u.title() == null || u.title().isBlank()) throw new Invalid("title is required");
        String precision = u.timePrecision() == null ? current.timePrecision() : u.timePrecision();
        try { new TimeSpan(u.startYear(), u.endYear(), precision); }
        catch (IllegalArgumentException ex) { throw new Invalid(ex.getMessage()); }
        writer.updateContent(id, u.title().trim(), u.summary(), u.startYear(), u.endYear(), precision);
        return done("poetry_content/" + id, List.of());
    }

    @Transactional
    public Written createSource(SourceCreate s) {
        id(s.id());
        if (s.title() == null || s.title().isBlank()) throw new Invalid("title is required");
        if (orZero(writer.existsSource(s.id())) > 0) throw new Invalid("source id already exists: " + s.id());
        if (s.sourceKind() != null && !Vocabulary.isMember(Vocabulary.SOURCE_KINDS, s.sourceKind()))
            throw new Invalid("source_kind outside vocabulary: " + s.sourceKind());
        if (s.reliability() != null && !Vocabulary.isMember(Vocabulary.RELIABILITIES, s.reliability()))
            throw new Invalid("reliability outside vocabulary: " + s.reliability());
        if (s.edition() == null || s.edition().isBlank())
            throw new Invalid("edition is required: an unversioned source can never be verified");
        List<String> notices = new ArrayList<>();
        if (s.sourceKind() == null || s.reliability() == null)
            notices.add("未分级：来源不能升 VERIFIED（C5_verified_source_without_grading）。");
        writer.insertSource(s);
        return done("poetry_source/" + s.id(), notices);
    }

    @Transactional
    public Written updateSource(String id, SourceUpdate u) {
        id(id);
        if (writer.draftSource(id) == null) throw new Invalid("source not found: " + id);
        if (u.sourceKind() != null && !Vocabulary.isMember(Vocabulary.SOURCE_KINDS, u.sourceKind()))
            throw new Invalid("source_kind outside vocabulary: " + u.sourceKind());
        if (u.reliability() != null && !Vocabulary.isMember(Vocabulary.RELIABILITIES, u.reliability()))
            throw new Invalid("reliability outside vocabulary: " + u.reliability());
        writer.updateSource(id, u);
        return done("poetry_source/" + id, List.of());
    }

    @Transactional
    public Written createClaim(ClaimCreate c) {
        id(c.id());
        if (!Vocabulary.isMember(Vocabulary.CLAIM_KINDS, c.claimKind()))
            throw new Invalid("claim_kind outside vocabulary: " + c.claimKind());
        if (!Vocabulary.isMember(Vocabulary.CERTAINTIES, c.certainty()))
            throw new Invalid("certainty outside vocabulary: " + c.certainty());
        if (c.propertyKey() == null || c.propertyKey().isBlank() || c.valueText() == null || c.valueText().isBlank())
            throw new Invalid("property_key and value_text are required");
        if (orZero(writer.existsContent(c.subjectId())) == 0)
            throw new Invalid("subject not found (录入顺序：先 content 后 claim): " + c.subjectId());
        if (orZero(writer.existsClaim(c.id())) > 0) throw new Invalid("claim id already exists: " + c.id());
        writer.insertClaim(c);
        List<String> notices = new ArrayList<>();
        if ("FACT".equals(c.claimKind()))
            notices.add("FACT 说法必须有已核查来源 + 可复查 locator，否则不能发布。");
        return done("poetry_claim/" + c.id(), notices);
    }

    @Transactional
    public Written updateClaim(String id, ClaimUpdate u) {
        id(id);
        if (u.certainty() != null && !Vocabulary.isMember(Vocabulary.CERTAINTIES, u.certainty()))
            throw new Invalid("certainty outside vocabulary: " + u.certainty());
        if (u.valueText() == null || u.valueText().isBlank()) throw new Invalid("value_text is required");
        int rows = writer.updateClaim(id, u.valueText(), u.certainty());
        if (rows != 1) throw new Invalid("claim not found: " + id);
        return done("poetry_claim/" + id, List.of());
    }

    @Transactional
    public Written cite(CitationCreate c) {
        id(c.claimId());
        if (orZero(writer.existsClaim(c.claimId())) == 0) throw new Invalid("claim not found: " + c.claimId());
        if (orZero(writer.existsSource(c.sourceId())) == 0) throw new Invalid("source not found: " + c.sourceId());
        if (c.locator() == null || c.locator().isBlank()) throw new Invalid("locator is required");
        List<String> notices = new ArrayList<>();
        String locator = c.locator().trim();
        if (locator.startsWith("待") || locator.contains("待核查") || locator.contains("待人工") || locator.contains("未核对"))
            notices.add("locator 是占位文字：这样的引用永远不能发布（C5_citation_locator_placeholder）。");
        writer.insertCitation(new CitationCreate(c.claimId(), c.sourceId(), locator, c.evidenceExcerpt()));
        return done("poetry_citation/" + c.claimId() + "/" + c.sourceId(), notices);
    }

    @Transactional
    public Written adopt(Adoption a) {
        if (orZero(writer.existsContent(a.subjectId())) == 0) throw new Invalid("subject not found: " + a.subjectId());
        if (a.propertyKey() == null || a.propertyKey().isBlank()) throw new Invalid("property_key is required");
        if (orZero(writer.existsClaim(a.claimId())) == 0) throw new Invalid("claim not found: " + a.claimId());
        List<DraftClaim> claims = writer.draftClaims(a.subjectId());
        DraftClaim claim = claims.stream().filter(x -> x.id().equals(a.claimId())).findFirst()
            .orElseThrow(() -> new Invalid("claim " + a.claimId() + " does not belong to subject " + a.subjectId()));
        if (!claim.propertyKey().equals(a.propertyKey()))
            throw new Invalid("property_key mismatch: claim has " + claim.propertyKey());
        if ("time.span".equals(a.propertyKey())) {
            List<String> adoptNotices = new ArrayList<>();
            adoptNotices.add("已采用一说；同一 subject+property 的其他说法仍在库里并存。");
            writer.replaceSelection(a);
            return done("poetry_claim_selection/" + a.subjectId() + "/" + a.propertyKey(), adoptNotices);
        }
        writer.replaceSelection(a);
        return done("poetry_claim_selection/" + a.subjectId() + "/" + a.propertyKey(), List.of());
    }

    @Transactional
    public Written upsertCoverage(CoverageWrite c) {
        id(c.id());
        if (!Vocabulary.isMember(Vocabulary.ENTITY_TYPES, c.entityType()))
            throw new Invalid("entity_type outside vocabulary: " + c.entityType());
        if (!Vocabulary.isMember(Vocabulary.COVERAGE_KINDS, c.coverageKind()))
            throw new Invalid("coverage_kind outside vocabulary: " + c.coverageKind());
        if (!Vocabulary.isMember(Vocabulary.STATUSES, c.status()))
            throw new Invalid("status outside vocabulary: " + c.status());
        if (c.fromYear() == null || c.toYear() == null || c.fromYear() > c.toYear())
            throw new Invalid("from_year must be <= to_year");
        if (c.fromYear() == 0 || c.toYear() == 0) throw new Invalid("there is no year zero");
        CoverageWrite stored = new CoverageWrite(c.id(), c.entityType(), c.fromYear(), c.toYear(),
            c.coverageKind(), c.status(), c.note(), c.updatedBy() == null ? "unknown" : c.updatedBy());
        if (writer.updateCoverage(stored) == 0) writer.insertCoverage(stored);
        return done("poetry_coverage/" + c.id(), List.of());
    }

    public DraftContent content(String id) { return writer.draftContent(id); }
    public List<DraftContent> contents(String type, String status, String q, int limit, int offset) {
        return List.copyOf(writer.draftContents(type, status, q, limit, offset));
    }
    public List<DraftSource> sources(String status, int limit, int offset) {
        return List.copyOf(writer.draftSources(status, limit, offset));
    }
    public DraftSource source(String id) { return writer.draftSource(id); }
    public List<DraftClaim> claims(String subjectId) { return List.copyOf(writer.draftClaims(subjectId)); }
    public List<DraftCitation> citations(String claimId) { return List.copyOf(writer.draftCitations(claimId)); }
    public List<DraftSelection> selections(String subjectId) { return List.copyOf(writer.draftSelections(subjectId)); }
    public List<DraftCoverage> coverage(String type) { return List.copyOf(writer.draftCoverage(type)); }

    private void requireReferences(String type, ContentCreate c) {
        switch (type) {
            case "PERIOD" -> {
                require(c.dynastyId(), "dynasty_id", true);
                requireParent(c.parentId(), "PERIOD", "parent_id");
                reference(c.dynastyId(), "dynasty_id");
            }
            case "PERSON" -> reference(c.dynastyId(), "dynasty_id");
            case "WORK" -> { reference(c.dynastyId(), "dynasty_id"); reference(c.placeId(), "creation_place_id"); }
            case "EVENT" -> reference(c.placeId(), "place_id");
            case "PLACE" -> requireParent(c.parentId(), "PLACE", "parent_id");
            case "EXPERIENCE" -> {
                require(c.personId(), "person_id", true);
                reference(c.personId(), "person_id");
                reference(c.eventId(), "event_id");
                reference(c.placeId(), "place_id");
            }
            case "THEME" -> {
                requireParent(c.periodScope(), "PERIOD", "period_scope");
                reference(c.periodScope(), "period_scope");
            }
            default -> { }
        }
    }

    private void require(String value, String field, boolean mandatory) {
        if (mandatory && (value == null || value.isBlank())) throw new Invalid(field + " is required");
    }

    private void reference(String value, String field) {
        if (value == null || value.isBlank()) return;
        if (orZero(writer.existsContent(value)) == 0)
            throw new Invalid(field + " points at a row that does not exist: " + value);
    }

    private void requireParent(String value, String expectedType, String field) {
        if (value == null || value.isBlank()) return;
        String actual = writer.entityType(value);
        if (actual == null) throw new Invalid(field + " points at a row that does not exist: " + value);
        if (!expectedType.equals(actual))
            throw new Invalid(field + " must point at " + expectedType + ", found " + actual + ": " + value);
    }

    private Written done(String subject, List<String> notices) {
        AuditRunner.Result result = audit.run();
        if (!result.clean())
            throw new Dirty("write left the library unverified, rolling back: " + result.nonZero().stream().limit(10).toList());
        return new Written(subject, true, List.copyOf(notices), result.totalChecks(), List.of());
    }

    private static void id(String value) {
        if (value == null || !value.matches(ID_PATTERN))
            throw new Invalid("id must match " + ID_PATTERN + " (got: " + value + ")");
    }

    private static int orZero(Integer value) { return value == null ? 0 : value; }
}
