package com.timeline.vpn.model.vo;

import lombok.Data;

/** 会话里的一条消息。createdAt 为毫秒时间戳。 */
@Data
public class ChatMessageVo {
    private long id;
    private long sessionId;
    private String role;
    private String content;
    private int type;
    private String clientMsgId;
    private long createdAt;
}
