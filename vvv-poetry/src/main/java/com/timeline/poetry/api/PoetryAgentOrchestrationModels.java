package com.timeline.poetry.api;

import com.fasterxml.jackson.databind.JsonNode;

/** Internal orchestration contracts. These persist workflow metadata only, never Poetry facts. */
public final class PoetryAgentOrchestrationModels {
    private PoetryAgentOrchestrationModels() {}

    public record TaskCreate(String taskId, String workId, String title, String taskType,
                             String requestedBy, String requestedRole, String instructions,
                             String requestedProfile) {}
    public record RunCreate(String runId, String mandateId, String runtime, String profileName,
                            String profileFingerprint, JsonNode profileManifest) {}
    public record RuntimeAdmission(String status, String runtimeThreadId, String runtimeRunId, String reason) {}
    public record RunStateChange(String status, String reason) {}
    public record EventAppend(String eventType, JsonNode payload) {}
}
