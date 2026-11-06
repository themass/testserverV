package com.timeline.poetry.api;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.List;
import java.util.Map;

/**
 * Contracts for the restricted Agent-facing domain API. These are deliberately separate from
 * student-facing models: Agent traffic is authenticated, correlated, auditable and DRAFT-only.
 */
public final class PoetryAgentModels {
    private PoetryAgentModels() {}

    public record AgentResponse<T>(String status, T data, List<String> auditRefs, String nextAction) {
        public static <T> AgentResponse<T> ok(T data, List<String> refs) {
            return new AgentResponse<>("OK", data, List.copyOf(refs), "NONE");
        }
        public static <T> AgentResponse<T> review(T data, List<String> refs) {
            return new AgentResponse<>("REVIEW_REQUIRED", data, List.copyOf(refs), "HUMAN_REVIEW");
        }
        @SuppressWarnings("unchecked")
        public static <T> AgentResponse<T> rejected(String reason) {
            return new AgentResponse<>("REJECTED", (T) Map.of("reason", reason), List.of(), "REPLAN");
        }
        @SuppressWarnings("unchecked")
        public static <T> AgentResponse<T> conflict(String reason) {
            return new AgentResponse<>("CONFLICT", (T) Map.of("reason", reason), List.of(), "REPLAN");
        }
    }

    /** schema_version=1 DRAFT candidate from the bounded BFF/MCP handoff. */
    public record ProposalCreate(String workId, String proposalId, JsonNode proposal) {}
    public record ProposalReview(String reviewId, String reviewerId, String decision, String comment) {}
    public record ProposalApply(String reviewId) {}
    public record CompileRequest(String scriptVersion) {}

    public record Snapshot(Object work, Object workInfo, List<?> versions, List<?> lines,
                           List<?> claims, List<?> citations, List<?> backgrounds,
                           List<?> annotations, List<?> sources) {}
    public record Gap(String code, String severity, String message, String targetRef) {}
    public record GapReport(String workId, List<Gap> gaps, int auditChecks, List<String> auditNonZero) {}
}
