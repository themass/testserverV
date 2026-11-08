package com.timeline.vpn.service.impl.handle.chat;

/**
 * 流式回复失败：上游返回了错误体（HTTP 非 2xx，或 HTTP 200 但不是 SSE 流），
 * 或流正常结束却没有任何文字。message 直接作为 SSE 帧的 error 字段展示给客户端。
 * 抛出它时不会保存助手消息。
 */
public class StreamUpstreamException extends RuntimeException {
    public StreamUpstreamException(String userMessage) {
        super(userMessage);
    }
}
