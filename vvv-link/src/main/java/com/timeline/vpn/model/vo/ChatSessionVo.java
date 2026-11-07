package com.timeline.vpn.model.vo;

import lombok.Data;

/** 会话列表项。时间为毫秒时间戳；lastMessage 截断到 40 字。 */
@Data
public class ChatSessionVo {
    private long id;
    private String name;
    private Integer characterId;
    private String roleId;
    private long createdAt;
    private long updatedAt;
    private String lastMessage;
    private long messageCount;
}
