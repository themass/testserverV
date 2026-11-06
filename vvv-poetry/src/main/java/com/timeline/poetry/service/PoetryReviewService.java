package com.timeline.poetry.service;

import com.timeline.poetry.domain.PublicationGate;
import com.timeline.poetry.domain.Vocabulary;
import com.timeline.poetry.persistence.PoetryWriter;
import org.springframework.transaction.annotation.Transactional;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * The write side. Its only job is to make the publish rules exist in ONE place: a publish is
 * allowed when (a) the subject itself passes the gate, (b) the 106 audit checks are all zero,
 * and (c) a human reviewer is named. Everything else is bookkeeping into poetry_review_log.
 * No endpoint here can create content — content is created by reviewed SQL scripts, so the
 * authored draft always exists before this service is asked to publish it.
 */
public class PoetryReviewService {
    private static final Map<String, String> TABLES = Map.of(
        "content", "poetry_content", "claim", "poetry_claim",
        "text_version", "poetry_text_version", "source", "poetry_source");
    private final PoetryWriter writer;
    private final AuditRunner audit;

    public PoetryReviewService(PoetryWriter writer, AuditRunner audit) { this.writer = writer; this.audit = audit; }

    public record Decision(boolean accepted, String subject, List<String> blocking, int auditChecks) {}

    @Transactional
    public Decision publish(String type, String id, String reviewer, String note) {
        String table = table(type);
        List<String> blocking = new ArrayList<>(PublicationGate.reviewerProblems(reviewer));
        if ("claim".equals(type)) { // problems() re-checks the reviewer; the set below removes the duplicate
            blocking.clear();
            String kind = writer.claimKind(id);
            if (kind == null) return blocked(type, id, List.of("claim not found"), 0);
            blocking.addAll(PublicationGate.problems(reviewer, kind, writer.verifiedSourceIdsForClaim(id),
                Integer.valueOf(1).equals(writer.claimDramatizationLabeled(id))));
        } else if ("source".equals(type)) {
            blocking.addAll(PublicationGate.sourceProblems(reviewer, writer.sourceKind(id), writer.sourceReliability(id)));
        } else if ("text_version".equals(type)) {
            blocking.addAll(PublicationGate.versionProblems(reviewer,
                orZero(writer.versionVerifiedSourceCount(id)) > 0,
                orZero(writer.versionLineCount(id)), writer.versionScript(id)));
        } else if ("content".equals(type)) {
            if (writer.contentRevision(id) == null) blocking.add("content row not found");
        }
        if (!blocking.isEmpty()) return blocked(type, id, blocking, 0);

        AuditRunner.Result before = audit.run();
        if (!before.clean())
            return blocked(type, id, before.nonZero().stream().limit(20).toList(), before.totalChecks());

        int revision = orZero(writer.contentRevision(id));
        int rows = switch (type) {
            case "content" -> writer.updateContentStatus(id, "PUBLISHED", reviewer.trim());
            case "claim" -> writer.updateClaimStatus(id, "PUBLISHED", reviewer.trim());
            case "text_version" -> writer.updateVersionStatus(id, "PUBLISHED", reviewer.trim());
            default -> writer.updateSourceVerification(id, "VERIFIED", reviewer.trim());
        };
        if (rows != 1) return blocked(type, id, List.of("row vanished during publish"), before.totalChecks());
        writer.appendReviewLog(table, id, revision + 1, "PUBLISHED", reviewer.trim(),
            note == null || note.isBlank() ? "通过全部核查后发布" : note);

        // Second pass on the resulting state. If publishing this row breaks any check, the whole
        // transaction is rolled back: it is impossible to leave the library dirty through this API.
        AuditRunner.Result after = audit.run();
        if (!after.clean())
            throw new IllegalStateException("publish would leave the library unclean, rolling back: "
                + after.nonZero().stream().limit(10).toList());
        return new Decision(true, table + '/' + id, List.of(), after.totalChecks());
    }

    @Transactional
    public Decision retract(String type, String id, String reviewer, String note) {
        String table = table(type);
        List<String> blocking = new ArrayList<>(PublicationGate.reviewerProblems(reviewer));
        if (!blocking.isEmpty()) return blocked(type, id, blocking, 0);
        int revision = orZero(writer.contentRevision(id));
        switch (type) {
            case "content" -> writer.updateContentStatus(id, "RETRACTED", reviewer.trim());
            case "claim" -> writer.updateClaimStatus(id, "RETRACTED", reviewer.trim());
            case "text_version" -> writer.updateVersionStatus(id, "RETRACTED", reviewer.trim());
            default -> writer.updateSourceVerification(id, "REJECTED", reviewer.trim());
        }
        writer.appendReviewLog(table, id, revision + 1, "RETRACTED", reviewer.trim(),
            note == null || note.isBlank() ? "撤回：不再对学生可见" : note);
        return new Decision(true, table + '/' + id, List.of(), 0);
    }

    @Transactional
    public Decision log(String type, String id, String decision, String reviewer, String note) {
        String table = table(type);
        List<String> blocking = new ArrayList<>(PublicationGate.reviewerProblems(reviewer));
        if (!Vocabulary.isMember(Vocabulary.REVIEW_DECISIONS, decision))
            blocking.add("decision outside vocabulary: " + decision);
        if (!blocking.isEmpty()) return blocked(type, id, blocking, 0);
        writer.appendReviewLog(table, id, orZero(writer.contentRevision(id)), decision, reviewer.trim(), note);
        return new Decision(true, table + '/' + id, List.of(), 0);
    }

    public AuditRunner.Result audit() { return audit.run(); }

    public Map<String, Object> status() {
        AuditRunner.Result result = audit.run();
        return Map.of("publishedContent", orZero(writer.publishedContentCount()),
            "publishedTextVersions", orZero(writer.publishedVersionCount()),
            "publishedBackgrounds", orZero(writer.publishedBackgroundCount()),
            "verifiedSources", orZero(writer.verifiedSourceCount()),
            "auditChecks", result.totalChecks(), "auditNonZero", result.nonZero());
    }

    private static String table(String type) {
        String table = TABLES.get(type == null ? "" : type.toLowerCase(Locale.ROOT));
        if (table == null) throw new IllegalArgumentException("Unsupported subject type: " + type);
        return table;
    }

    private static int orZero(Integer value) { return value == null ? 0 : value; }

    private static Decision blocked(String type, String id, List<String> blocking, int checks) {
        return new Decision(false, tableStatic(type) + '/' + id, List.copyOf(blocking), checks);
    }

    private static String tableStatic(String type) {
        String table = TABLES.get(type == null ? "" : type.toLowerCase(Locale.ROOT));
        return table == null ? "?" : table;
    }
}
