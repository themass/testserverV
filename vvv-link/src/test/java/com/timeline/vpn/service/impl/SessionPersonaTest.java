package com.timeline.vpn.service.impl;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** 人设属于会话：同一段历史里不会出现两个角色的提示词。 */
class SessionPersonaTest {

    @Test
    void sessionRoleWinsOverADifferentRoleInTheRequest() {
        SessionPersona p = SessionPersona.resolve(null, "detective", null, "chef", true);
        assertEquals("detective", p.roleId());
        assertFalse(p.shouldPersist());
        assertTrue(p.requestIgnored(), "被忽略的请求要能被发现，旧客户端排查靠它");
    }

    @Test
    void aBlankRequestUsesTheSessionRole() {
        SessionPersona p = SessionPersona.resolve(null, "detective", null, "  ", true);
        assertEquals("detective", p.roleId());
        assertFalse(p.requestIgnored());
    }

    @Test
    void theSameRoleInTheRequestIsNotReportedAsIgnored() {
        assertFalse(SessionPersona.resolve(null, "detective", null, "detective", true).requestIgnored());
    }

    @Test
    void aDefaultAssistantSessionWithHistoryStaysDefaultWhateverTheRequestSays() {
        // 回归：默认助手聊了很多句，之后请求带了 roleId，不能把这段历史改标成那个角色
        SessionPersona p = SessionPersona.resolve(null, null, null, "chef", true);
        assertNull(p.roleId());
        assertNull(p.characterId());
        assertFalse(p.shouldPersist());
        assertTrue(p.requestIgnored());
    }

    @Test
    void anEmptySessionTakesTheRoleFromTheFirstRequestAndStoresIt() {
        SessionPersona p = SessionPersona.resolve(null, null, null, "chef", false);
        assertEquals("chef", p.roleId());
        assertTrue(p.shouldPersist());
        assertFalse(p.requestIgnored());
    }

    @Test
    void anEmptySessionWithoutAnyPersonaStaysDefault() {
        SessionPersona p = SessionPersona.resolve(null, null, 0, "", false);
        assertNull(p.roleId());
        assertNull(p.characterId());
        assertFalse(p.shouldPersist());
    }

    @Test
    void aCharacterSessionKeepsItsCharacterAndIgnoresADifferentOne() {
        SessionPersona p = SessionPersona.resolve(7, null, 9, null, true);
        assertEquals(7, p.characterId());
        assertTrue(p.requestIgnored());
    }

    @Test
    void zeroOrNegativeCharacterIdsMeanNone() {
        SessionPersona p = SessionPersona.resolve(0, null, -1, null, false);
        assertNull(p.characterId());
        assertFalse(p.shouldPersist());
    }
}
