package com.timeline.vpn.model.vo;

/**
 * 流式对话的单个 SSE 数据帧。
 * 注意：流式接口不走 JsonResult 的 AES 封装（SseEmitter 绕过了那层 Jackson 序列化），
 * 这里的内容是明文，所以绝不能把加密密钥/鉴权信息塞进来。
 */
public class StreamChunk {
    private String id;
    private String delta;
    private boolean done;
    private String error;

    public StreamChunk() {
    }

    public StreamChunk(String id, String delta, boolean done, String error) {
        this.id = id;
        this.delta = delta;
        this.done = done;
        this.error = error;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getDelta() {
        return delta;
    }

    public void setDelta(String delta) {
        this.delta = delta;
    }

    public boolean isDone() {
        return done;
    }

    public void setDone(boolean done) {
        this.done = done;
    }

    public String getError() {
        return error;
    }

    public void setError(String error) {
        this.error = error;
    }
}
