package com.timeline.vpn.service.impl;

import org.apache.commons.lang3.StringUtils;

/**
 * 一个会话用谁的人设。
 *
 * 每个用户与每个角色是一段独立的对话历史，所以人设属于会话，不属于某一次请求：
 * 会话里已经有人设，就一直用它，请求里带的不同角色一律忽略。
 * 否则同一段历史里前半是侦探、后半换成厨师的提示词，模型会顺着历史继续扮演前一个角色，
 * 用户看到的就是“换了角色但没换”。
 *
 * 会话里还没有人设时才用请求带的，而且只在会话还没有任何消息时才写进去：
 * 一段已经聊了很多句的默认助手历史，不能事后被改标成某个角色的历史。
 */
public final class SessionPersona {

    private final Integer characterId;
    private final String roleId;
    private final boolean persist;
    private final boolean requestIgnored;

    private SessionPersona(Integer characterId, String roleId, boolean persist, boolean requestIgnored) {
        this.characterId = characterId;
        this.roleId = roleId;
        this.persist = persist;
        this.requestIgnored = requestIgnored;
    }

    public static SessionPersona resolve(Integer sessionCharacterId, String sessionRoleId,
                                         Integer requestCharacterId, String requestRoleId,
                                         boolean sessionHasMessages) {
        Integer sCid = positive(sessionCharacterId);
        String sRid = StringUtils.trimToNull(sessionRoleId);
        Integer rCid = positive(requestCharacterId);
        String rRid = StringUtils.trimToNull(requestRoleId);

        if (sCid != null || sRid != null) {
            // 会话的人设说了算
            boolean differs = (rRid != null && !rRid.equals(sRid)) || (rCid != null && !rCid.equals(sCid));
            return new SessionPersona(sCid, sRid, false, differs);
        }
        if (rCid == null && rRid == null) {
            return new SessionPersona(null, null, false, false);
        }
        if (sessionHasMessages) {
            // 已经有历史的默认助手会话：不能事后改标成某个角色，请求里的人设这一轮也不采用
            return new SessionPersona(null, null, false, true);
        }
        return new SessionPersona(rCid, rRid, true, false);
    }

    private static Integer positive(Integer v) {
        return v != null && v > 0 ? v : null;
    }

    /** 这一轮要用的旧人设 id，没有为 null。 */
    public Integer characterId() {
        return characterId;
    }

    /** 这一轮要用的目录角色 id，没有为 null。 */
    public String roleId() {
        return roleId;
    }

    /** 是否要把人设写进会话（只有“空会话第一次带人设”才写）。 */
    public boolean shouldPersist() {
        return persist;
    }

    /** 请求带了与会话不一致的人设而被忽略，调用方记一条日志，方便排查旧客户端。 */
    public boolean requestIgnored() {
        return requestIgnored;
    }
}
