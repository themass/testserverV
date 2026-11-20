package com.timeline.game.api;

/**
 * HTTP 统一响应（docs/game/api.md 约定）：HTTP 状态码表达传输层结果，
 * errno 表达业务结果（0 = 成功）；不碰 legacy JsonResult / AES。
 */
public record GameResponse<T>(int errno, T data, String error) {

    public static <T> GameResponse<T> ok(T data) { return new GameResponse<>(0, data, null); }

    public static <T> GameResponse<T> err(int errno, String error) { return new GameResponse<>(errno, null, error); }

    /** 业务错误码沿用 GameErrorCode 字符串，客户端与 WS 错误同一词表。 */
    public static <T> GameResponse<T> fail(com.timeline.game.protocol.GameErrorCode code, String message) {
        return new GameResponse<>(1, null, code.name() + (message == null ? "" : ":" + message));
    }
}
