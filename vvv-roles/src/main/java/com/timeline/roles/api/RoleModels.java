package com.timeline.roles.api;

import java.util.List;

/** Wire shapes of /api/roles/v1. The prompt is never sent to clients; the chat endpoint resolves it by id. */
public final class RoleModels {
    private RoleModels() {}

    public record Response<T>(int code, T data, String message) {
        public static <T> Response<T> ok(T data) { return new Response<>(0, data, "ok"); }
    }

    public record Page<T>(List<T> items, int total, int limit, int offset) {}

    public record DivisionItem(String id, String label, String icon, String color, int count) {}

    public record RoleItem(String id, String division, String name, String description, String emoji,
                           String color, String vibe, boolean featured) {}
}
