package com.timeline.poetry.domain;

import java.util.ArrayList;
import java.util.List;

/** Preflight rules, not an authorization to publish. Public SQL independently fails closed. */
public final class PublicationGate {
    private PublicationGate() {}
    public static List<String> problems(String reviewer, String kind, List<String> verifiedSourceIds,
                                        boolean dramatizationLabeled) {
        List<String> problems = new ArrayList<>();
        if (reviewer == null || reviewer.isBlank()) problems.add("Human reviewer is required");
        if (!List.of("FACT", "INTERPRETATION", "DRAMATIZATION").contains(kind == null ? "" : kind))
            problems.add("Invalid claim kind");
        if ("DRAMATIZATION".equals(kind)) {
            if (!dramatizationLabeled) problems.add("Dramatization must be explicitly labeled");
        } else if (verifiedSourceIds == null || verifiedSourceIds.stream().noneMatch(s -> s != null && !s.isBlank())) {
            problems.add("At least one verified source is required");
        }
        return List.copyOf(problems);
    }
}
