package com.timeline.vpn.common.exception;

/**
 * @Author： liguoqing
 * @Date： 2024/4/9 21:38
 * @Describe：
 */
public class LlmRuntimeException extends RuntimeException {
    public LlmRuntimeException(String message) {
        super(message);
    }

    public LlmRuntimeException(Exception e) {
        super(e);
    }
}
