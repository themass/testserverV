package com.timeline.vpn.model.form;

import lombok.Data;
import lombok.ToString;

/**
 * 对话请求。历史由服务端按 sessionId 读取，客户端只发当轮新消息。
 */
@Data
@ToString
public class ChatContentForm {
    /** 当轮新用户消息。regenerate=true 时可以为空。 */
    private String text;
    /** 客户端消息 id（同会话内重发时用于幂等）；同时作为助手回复的 choice id。 */
    private String id;
    private String settingName;
    /** 会话 id；<=0 或不传时服务端新建会话，新 id 在响应里返回。 */
    private long sessionId;
    /** 为 true 时不写入用户消息：删掉最后一条用户消息之后的回复，重新回答。 */
    private boolean regenerate;

    /**
     * 按角色表 id 选人设。为空时回退到会话里存的人设，再回退到 settingName 旧逻辑。
     */
    private Integer characterId;

    /**
     * 角色目录（vvv-roles，/api/roles/v1）里的角色 id。优先级高于 characterId；
     * 为空时回退到会话里存的 roleId。
     */
    private String roleId;
}
