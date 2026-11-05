package com.timeline.vpn.model.form;

import lombok.Data;
import lombok.ToString;

@Data
@ToString
public class ChatContentForm {
    private String content;
    private String text;
    private String id;
    private String charater;
    private String settingName;
    private long sessionId;

    /**
     * 新协议字段：按角色表 id 选人设，取代一直没生效的 charater 字段
     * （客户端以前传 charater 一个字符串，但后端 getPrompt 从未读过它，一直在走
     * settingName 的硬编码 switch；见 docs/agent-and-media-roadmap.md 第五节）。
     * 为空时回退到 settingName 的旧逻辑，保证老客户端不受影响。
     */
    private Integer characterId;

    /**
     * 角色目录（vvv-roles，/api/roles/v1）里的角色 id，例如 "engineering-frontend-developer"。
     * 优先级高于 characterId；为空或在目录里查不到时，继续走 characterId / settingName 的旧逻辑。
     */
    private String roleId;
}
