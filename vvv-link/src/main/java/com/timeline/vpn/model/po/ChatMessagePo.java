package com.timeline.vpn.model.po;

import lombok.Data;

import java.util.Date;

/** 对话消息（表 vpn.chat_message）。 */
@Data
public class ChatMessagePo {
    private long id;
    private long sessionId;
    private long userId;
    /** user / assistant */
    private String role;
    private String content;
    /** 0 文本 1 语音 2 图片 3 视频 4 文件 */
    private int type;
    private String clientMsgId;
    private Date createdAt;
    private int deleted;
}
