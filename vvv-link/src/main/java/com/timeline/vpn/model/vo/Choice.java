package com.timeline.vpn.model.vo;

import lombok.ToString;

@ToString
public class Choice {
    private String id;
    /** 本轮所属会话 id（服务端回填）。 */
    private long sessionId;
    private int index;
    private Message message;
    private String logprobs;
    private String finish_reason;
    private String prod;
    /** 本轮用户消息 id（服务端）。 */
    private long userMessageId;
    /** 本轮助手消息 id（服务端）；回复为空时为 0。 */
    private long assistantMessageId;
    public Choice() {
    }

    public Choice(int index, Message message, String logprobs, String finish_reason) {
        this.index = index;
        this.message = message;
        this.logprobs = logprobs;
        this.finish_reason = finish_reason;
    }

    public int getIndex() {
        return index;
    }

    public void setIndex(int index) {
        this.index = index;
    }

    public Message getMessage() {
        return message;
    }

    public void setMessage(Message message) {
        this.message = message;
    }

    public String getLogprobs() {
        return logprobs;
    }

    public void setLogprobs(String logprobs) {
        this.logprobs = logprobs;
    }

    public String getFinish_reason() {
        return finish_reason;
    }

    public void setFinish_reason(String finish_reason) {
        this.finish_reason = finish_reason;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public long getSessionId() {
        return sessionId;
    }

    public void setSessionId(long sessionId) {
        this.sessionId = sessionId;
    }

    public long getUserMessageId() {
        return userMessageId;
    }

    public void setUserMessageId(long userMessageId) {
        this.userMessageId = userMessageId;
    }

    public long getAssistantMessageId() {
        return assistantMessageId;
    }

    public void setAssistantMessageId(long assistantMessageId) {
        this.assistantMessageId = assistantMessageId;
    }

    public String getProd() {
        return prod;
    }

    public void setProd(String prod) {
        this.prod = prod;
    }

}
