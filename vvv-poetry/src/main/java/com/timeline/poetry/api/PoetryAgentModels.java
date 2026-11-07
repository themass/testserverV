package com.timeline.poetry.api;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.JsonNode;
import java.util.List;
import java.util.Map;

/**
 * Contracts for the restricted Agent-facing domain API. These are deliberately separate from
 * student-facing models: Agent traffic is authenticated, correlated, auditable and DRAFT-only.
 */
public final class PoetryAgentModels {
    private PoetryAgentModels() {}

    public record AgentResponse<T>(
            @JsonProperty("status") String status,
            @JsonProperty("data") T data,
            @JsonProperty("audit_refs") List<String> auditRefs,
            @JsonProperty("next_action") String nextAction) {
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
    // Request keys are explicit snake_case (what the MCP bridge sends); camelCase is still accepted
    // so a caller written against the old implicit naming keeps working.
    public record ProposalCreate(
            @JsonProperty("work_id") @JsonAlias("workId") String workId,
            @JsonProperty("proposal_id") @JsonAlias("proposalId") String proposalId,
            @JsonProperty("proposal") JsonNode proposal) {}
    public record ProposalReview(
            @JsonProperty("review_id") @JsonAlias("reviewId") String reviewId,
            @JsonProperty("reviewer_id") @JsonAlias("reviewerId") String reviewerId,
            @JsonProperty("decision") String decision,
            @JsonProperty("comment") String comment) {}
    public record ProposalApply(@JsonProperty("review_id") @JsonAlias("reviewId") String reviewId) {}
    public record CompileRequest(@JsonProperty("script_version") @JsonAlias("scriptVersion") String scriptVersion) {}

    public record Snapshot(Object work, Object workInfo, List<?> versions, List<?> lines,
                           List<?> claims, List<?> citations, List<?> backgrounds,
                           List<?> annotations, List<?> sources) {}
    public record Gap(
            @JsonProperty("code") String code,
            @JsonProperty("severity") String severity,
            @JsonProperty("message") String message,
            @JsonProperty("target_ref") String targetRef) {}
    public record GapReport(
            @JsonProperty("work_id") String workId,
            @JsonProperty("gaps") List<Gap> gaps,
            @JsonProperty("audit_checks") int auditChecks,
            @JsonProperty("audit_non_zero") List<String> auditNonZero) {}
}
