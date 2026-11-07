package com.timeline.poetry.api;

import com.fasterxml.jackson.annotation.JsonProperty;

/** Publish side models (architecture review P0-1 / P0-2). Snake_case on the wire, as the compiler's manifest. */
public final class PoetryPublishModels {
    private PoetryPublishModels() {}

    /** Body of POST /draft/script/{id}/{version}/publish. bundle_hash must match a manifest under poetry.bundleRoot. */
    public record ScriptPublish(
        @JsonProperty("bundle_hash") String bundleHash,
        @JsonProperty("compiled_by") String compiledBy,
        @JsonProperty("compiled_at") String compiledAt) {}

    /** The three facts a script publish depends on, read in one statement. */
    public record ScriptGate(String status, String bundleHash, String textVersionId) {}
}
