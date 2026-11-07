package com.timeline.poetry.api;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.JsonNode;

/** Internal orchestration contracts. These persist workflow metadata only, never Poetry facts. */
public final class PoetryAgentOrchestrationModels {
    private PoetryAgentOrchestrationModels() {}

    // Explicit snake_case wire names (what the control bridge sends); camelCase accepted as an alias.
    public record TaskCreate(
            @JsonProperty("task_id") @JsonAlias("taskId") String taskId,
            @JsonProperty("work_id") @JsonAlias("workId") String workId,
            @JsonProperty("title") String title,
            @JsonProperty("task_type") @JsonAlias("taskType") String taskType,
            @JsonProperty("requested_by") @JsonAlias("requestedBy") String requestedBy,
            @JsonProperty("requested_role") @JsonAlias("requestedRole") String requestedRole,
            @JsonProperty("instructions") String instructions,
            @JsonProperty("requested_profile") @JsonAlias("requestedProfile") String requestedProfile) {}
    public record RunCreate(
            @JsonProperty("run_id") @JsonAlias("runId") String runId,
            @JsonProperty("mandate_id") @JsonAlias("mandateId") String mandateId,
            @JsonProperty("runtime") String runtime,
            @JsonProperty("profile_name") @JsonAlias("profileName") String profileName,
            @JsonProperty("profile_fingerprint") @JsonAlias("profileFingerprint") String profileFingerprint,
            @JsonProperty("profile_manifest") @JsonAlias("profileManifest") JsonNode profileManifest) {}
    public record RuntimeAdmission(
            @JsonProperty("status") String status,
            @JsonProperty("runtime_thread_id") @JsonAlias("runtimeThreadId") String runtimeThreadId,
            @JsonProperty("runtime_run_id") @JsonAlias("runtimeRunId") String runtimeRunId,
            @JsonProperty("reason") String reason) {}
    public record RunStateChange(@JsonProperty("status") String status, @JsonProperty("reason") String reason) {}
    public record EventAppend(
            @JsonProperty("event_type") @JsonAlias("eventType") String eventType,
            @JsonProperty("payload") JsonNode payload) {}
}
