package com.timeline.vpn.model.po;

import lombok.Data;

import java.util.Date;

/** 对话会话（表 vpn.chat_session）。 */
@Data
public class ChatSessionPo {
    private long id;
    private long userId;
    private String name;
    private Integer characterId;
    private String roleId;
    private Date createdAt;
    private Date updatedAt;
    private int deleted;
}
