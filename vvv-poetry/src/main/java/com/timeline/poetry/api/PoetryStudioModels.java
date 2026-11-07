package com.timeline.poetry.api;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

/**
 * Poetry Studio 治理端点的请求/响应模型。
 * 所有 JSON 键都用显式 {@code @JsonProperty}(snake_case)，不依赖宿主的全局 Jackson 命名策略。
 */
public final class PoetryStudioModels {
    private PoetryStudioModels() {}

    /** 新端点统一信封：{status,data,audit_refs,next_action}。键名显式固定为 snake_case。 */
    public record StudioResponse<T>(
            @JsonProperty("status") String status,
            @JsonProperty("data") T data,
            @JsonProperty("audit_refs") List<String> auditRefs,
            @JsonProperty("next_action") String nextAction) {
        public static <T> StudioResponse<T> ok(T data, List<String> refs) {
            return new StudioResponse<>("OK", data, List.copyOf(refs), "NONE");
        }
        public static StudioResponse<java.util.Map<String, Object>> error(String status, String code, String message,
                                                                          Object details, String nextAction) {
            java.util.Map<String, Object> data = new java.util.LinkedHashMap<>();
            data.put("code", code);
            data.put("reason", message);
            if (details != null) data.put("details", details);
            return new StudioResponse<>(status, data, List.of(), nextAction);
        }
    }

    /** PUT /studio/citations/{claimId}/{sourceId}/locator */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record LocatorUpdate(
            @JsonProperty("locator") String locator,
            @JsonProperty("evidence_excerpt") String evidenceExcerpt,
            @JsonProperty("reviewer") String reviewer,
            @JsonProperty("reviewer_role") String reviewerRole,
            @JsonProperty("note") String note) {}

    /** POST /studio/sources/{id}/verification */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record SourceVerification(
            @JsonProperty("decision") String decision,
            @JsonProperty("reviewer") String reviewer,
            @JsonProperty("reviewer_role") String reviewerRole,
            @JsonProperty("note") String note) {}

    /** item_index 用 Number 接收，服务层再校验"必须是整数"，避免 Jackson 把 1.5 静默截成 1。 */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record ItemDecision(
            @JsonProperty("item_index") Number itemIndex,
            @JsonProperty("decision") String decision,
            @JsonProperty("comment") String comment) {}

    /** PUT /studio/proposals/{id}/items */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record ItemDecisions(
            @JsonProperty("decisions") List<ItemDecision> decisions,
            @JsonProperty("reviewer") String reviewer,
            @JsonProperty("reviewer_role") String reviewerRole) {}
}
