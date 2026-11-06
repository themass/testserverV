package com.timeline.poetry.domain;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;

/**
 * The only place Java states the enumerated vocabularies. The same words are written out
 * again in audit_integrity_checks.sql (checks C7_*), because the audit runs inside the
 * database. Drift between the two is not tolerated: PoetrySelfCheck reads the audit file
 * from the classpath at startup and warns loudly when a word is missing there.
 * Changing a word list means changing three places at once: here, the audit SQL, and
 * docs/poetry/data-model.md section 4.
 */
public final class Vocabulary {
    private Vocabulary() {}

    public static final Set<String> ENTITY_TYPES = Set.of("DYNASTY", "PERIOD", "PLACE", "PERSON", "EVENT",
        "EXPERIENCE", "WORK", "BACKGROUND", "THEME");
    public static final Set<String> STATUSES = Set.of("DRAFT", "IN_REVIEW", "PUBLISHED", "RETRACTED");
    public static final Set<String> TIME_PRECISIONS = Set.of("UNKNOWN", "EXACT", "RANGE", "APPROXIMATE");
    public static final Set<String> CLAIM_KINDS = Set.of("FACT", "INTERPRETATION", "DRAMATIZATION");
    public static final Set<String> CERTAINTIES = Set.of("KNOWN", "LIKELY", "DISPUTED", "UNKNOWN");
    public static final Set<String> VERIFICATION_STATUSES = Set.of("PENDING", "VERIFIED", "REJECTED");
    public static final Set<String> SCRIPTS = Set.of("SIMPLIFIED", "TRADITIONAL");
    public static final Set<String> ATTRIBUTIONS = Set.of("PENDING", "ACCEPTED", "DISPUTED", "REJECTED");
    public static final Set<String> AUDIENCES = Set.of("PRIMARY", "JUNIOR", "SENIOR");
    public static final Set<String> LAYERS = Set.of("SCENE", "CITY", "WORLD", "PERSON");
    public static final Set<String> SOURCE_KINDS = Set.of("OFFICIAL_HISTORY", "YEAR_BOOK", "ANTHOLOGY",
        "TEXTBOOK", "MODERN_STUDY", "DIGITIZED_TEXT", "ONLINE_ENTRY", "OTHER");
    public static final Set<String> RELIABILITIES = Set.of("HIGH", "MEDIUM", "LOW", "UNKNOWN");
    public static final Set<String> COVERAGE_KINDS = Set.of("FULL", "PARTIAL", "PLANNED");
    public static final Set<String> REVIEW_DECISIONS = Set.of("SUBMITTED", "CHANGES_REQUESTED", "APPROVED",
        "REJECTED", "PUBLISHED", "RETRACTED", "REOPENED");
    public static final Set<String> THEME_ITEM_ROLES = Set.of("ANCHOR", "MEMBER", "CONTEXT");
    public static final Set<String> ANNOTATION_KINDS = Set.of("WORD", "PHRASE", "ALLUSION", "IMAGE", "RHYME", "OTHER");

    public static boolean isMember(Set<String> vocabulary, String value) {
        return value != null && vocabulary.contains(value);
    }

    /** Name -> word list, used by the startup check and by future write-side validation. */
    public static Map<String, Set<String>> all() {
        Map<String, Set<String>> out = new LinkedHashMap<>();
        out.put("entity_type", ENTITY_TYPES);
        out.put("status", STATUSES);
        out.put("time_precision", TIME_PRECISIONS);
        out.put("claim_kind", CLAIM_KINDS);
        out.put("certainty", CERTAINTIES);
        out.put("verification_status", VERIFICATION_STATUSES);
        out.put("script", SCRIPTS);
        out.put("attribution", ATTRIBUTIONS);
        out.put("audience", AUDIENCES);
        out.put("layer", LAYERS);
        out.put("source_kind", SOURCE_KINDS);
        out.put("reliability", RELIABILITIES);
        out.put("coverage_kind", COVERAGE_KINDS);
        out.put("review_decision", REVIEW_DECISIONS);
        out.put("theme_item_role", THEME_ITEM_ROLES);
        out.put("annotation_kind", ANNOTATION_KINDS);
        return Map.copyOf(out);
    }
}
