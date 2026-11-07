package com.timeline.poetry.api;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.SerializationFeature;

/**
 * Wire format of the Agent-facing API: JSON keys are snake_case, always.
 *
 * <p>The host application's global Jackson naming strategy is not visible from this module, so agent
 * traffic must not depend on it. Request/response records declare their keys explicitly with
 * {@code @JsonProperty}. Shared records that other endpoints also serialise (the {@code Draft*}
 * records) are left untouched and are converted here with a fixed snake_case mapper instead, so the
 * authoring endpoints keep whatever format they already have.
 */
public final class PoetryAgentWire {
    private PoetryAgentWire() {}

    private static final ObjectMapper SNAKE = new ObjectMapper()
        .findAndRegisterModules()
        .setPropertyNamingStrategy(PropertyNamingStrategies.SNAKE_CASE)
        .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS)
        .disable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES);

    /** Convert any bean/record graph to a tree whose keys are snake_case regardless of host config. */
    public static JsonNode snake(Object value) {
        return SNAKE.valueToTree(value);
    }
}
