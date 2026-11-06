package com.timeline.poetry.domain;

import java.util.ArrayList;
import java.util.List;

/** Preflight rules, not an authorization to publish. Public SQL independently fails closed. */
public final class PublicationGate {
    private PublicationGate() {}
    /** Reviewer names that can never authorise a publish (rehearsal and system markers). */
    public static List<String> reviewerProblems(String reviewer) {
        List<String> problems = new ArrayList<>();
        if (reviewer == null || reviewer.isBlank()) { problems.add("Human reviewer is required"); return problems; }
        String name = reviewer.trim();
        if (name.toUpperCase(java.util.Locale.ROOT).startsWith("DEMO")) problems.add("Rehearsal marker cannot publish: " + name);
        if (List.of("LIVE-PROBE", "SYSTEM", "ROOT", "NULL").contains(name.toUpperCase(java.util.Locale.ROOT)))
            problems.add("Machine identity cannot publish: " + name);
        return problems;
    }

    public static List<String> sourceProblems(String reviewer, String sourceKind, String reliability) {
        List<String> problems = new ArrayList<>(reviewerProblems(reviewer));
        if (!Vocabulary.isMember(Vocabulary.SOURCE_KINDS, sourceKind)) problems.add("source_kind missing or outside vocabulary");
        if (!Vocabulary.isMember(Vocabulary.RELIABILITIES, reliability)) problems.add("reliability missing or outside vocabulary");
        return problems;
    }

    public static List<String> versionProblems(String reviewer, boolean sourceVerified, int lineCount,
                                               String script) {
        List<String> problems = new ArrayList<>(reviewerProblems(reviewer));
        if (!sourceVerified) problems.add("Text version's base source is not verified");
        if (lineCount < 1) problems.add("Text version has no lines");
        if (!Vocabulary.isMember(Vocabulary.SCRIPTS, script)) problems.add("script missing or outside vocabulary");
        return problems;
    }

    public static List<String> problems(String reviewer, String kind, List<String> verifiedSourceIds,
                                        boolean dramatizationLabeled) {
        List<String> problems = new ArrayList<>(reviewerProblems(reviewer));
        if (!Vocabulary.isMember(Vocabulary.CLAIM_KINDS, kind)) problems.add("Invalid claim kind");
        if ("DRAMATIZATION".equals(kind)) {
            if (!dramatizationLabeled) problems.add("Dramatization must be explicitly labeled");
        } else if (verifiedSourceIds == null || verifiedSourceIds.stream().noneMatch(s -> s != null && !s.isBlank())) {
            problems.add("At least one verified source is required");
        }
        return List.copyOf(problems);
    }
}
