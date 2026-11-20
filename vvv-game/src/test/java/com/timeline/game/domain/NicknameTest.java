package com.timeline.game.domain;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/** 昵称清洗与屏蔽词单测（镜像 TS packages/shared/test/nickname.test.ts 的全部预期）。 */
class NicknameTest {

    @Test
    void 去首尾空白() {
        assertEquals("海鸥", Nickname.sanitizeNickname("  海鸥 ", "x"));
    }

    @Test
    void 去控制字符() {
        assertEquals("海鸥", Nickname.sanitizeNickname("海\u0000鸥\n", "x"));
    }

    @Test
    void 超过十二个字符回退() {
        assertEquals("玩家 1", Nickname.sanitizeNickname("一二三四五六七八九十一二三", "玩家 1"));
    }

    @Test
    void 十二个字符按码点计emoji算一个() {
        String fish = "🐟".repeat(12);
        assertEquals(fish, Nickname.sanitizeNickname(fish, "x"));
    }

    @Test
    void 空串与非字符串回退() {
        assertEquals("玩家 2", Nickname.sanitizeNickname("   ", "玩家 2"));
        assertEquals("玩家 2", Nickname.sanitizeNickname(42, "玩家 2"));
    }

    @Test
    void 保留字前缀拒绝() {
        for (String n : new String[]{"电脑1", "机器人", "系统消息", "官方客服", "管理员小王", "Admin", "GM01", " 电脑"}) {
            assertFalse(Nickname.isNicknameAllowed(n), n);
        }
    }

    @Test
    void bot前缀含分隔符与全角变体同样拒绝() {
        for (String n : new String[]{"bot1号", "bot:9527", "ＢＯＴ小明", "b o t 阿明"}) {
            assertFalse(Nickname.isNicknameAllowed(n), n);
        }
        assertTrue(Nickname.isNicknameAllowed("rabbit跳")); // 只按前缀拦
    }

    @Test
    void 含机器人emoji拒绝() {
        assertFalse(Nickname.isNicknameAllowed("小🤖"));
    }

    @Test
    void 脏词包含匹配绕过分隔符全角与零宽也拦() {
        for (String n : new String[]{"傻逼", "大傻·逼", "ＦＵＣＫ", "f u c k", "f.u.c.k",
                                     "sh​it", "SHIT", "你好操你"}) {
            assertFalse(Nickname.isNicknameAllowed(n), n);
        }
    }

    @Test
    void 正常昵称通过() {
        for (String n : new String[]{"敏捷的海鸥", "沉默的狐狸", "电工老李", "玩家 1"}) {
            assertTrue(Nickname.isNicknameAllowed(n), n);
        }
    }

    @Test
    void 保留字只按前缀中间出现电脑不拦() {
        assertTrue(Nickname.isNicknameAllowed("我的电脑"));
    }

    @Test
    void sanitize本身不做屏蔽() {
        assertEquals("电脑1", Nickname.sanitizeNickname("电脑1", "x"));
    }

    @Test
    void 归一化NFKC小写去空白分隔符零宽() {
        assertEquals("fuck", Nickname.normalizeForBlocklist("ＦＵＣＫ"));
        assertEquals("admin", Nickname.normalizeForBlocklist("A d·m._i-n*　​"));
    }

    @Test
    void isBlocked与isAllowed互补() {
        assertTrue(Nickname.isNicknameBlocked("GM01"));
        assertFalse(Nickname.isNicknameBlocked("海鸥"));
    }
}
