package com.timeline.game.domain;

import java.text.Normalizer;
import java.util.List;

/**
 * 昵称清洗与屏蔽词（TS nickname.ts + nickname-blocklist.ts 直译）。
 * 调用方先 sanitizeNickname，再用 isNicknameAllowed 检查。
 */
public final class Nickname {

    private Nickname() {}

    private static final int MAX_NICKNAME_LENGTH = 12;

    /** 以这些词开头的昵称会被拒绝，防止冒充电脑与官方（已归一化：小写）。 */
    public static final List<String> RESERVED_PREFIXES =
        List.of("电脑", "机器人", "系统", "官方", "管理员", "admin", "gm", "bot");

    /** 出现在昵称任意位置即拒绝。 */
    public static final List<String> RESERVED_CONTAINS = List.of("🤖");

    // TODO(P5)：这只是一份很短的种子表。公开上线前必须换成经授权、人工审核过的正式词库。
    public static final List<String> PROFANITY = List.of("傻逼", "操你", "fuck", "shit");

    /**
     * 昵称是字符串且未命中保留字前缀或屏蔽词。
     * （Java 版调用方保证入参是清洗后的字符串；TS 的 typeof 检查在协议解码层做。）
     */
    public static boolean isNicknameAllowed(String input) {
        return input != null && !isNicknameBlocked(input);
    }

    /** 去控制字符与首尾空白，按码点计 1–12 个字符，否则回退。本函数不做屏蔽检查。 */
    public static String sanitizeNickname(Object input, String fallback) {
        if (!(input instanceof String s)) return fallback;
        StringBuilder sb = new StringBuilder(s.length());
        for (int i = 0; i < s.length(); ) {
            int cp = s.codePointAt(i);
            i += Character.charCount(cp);
            if (!Character.isISOControl(cp)) sb.appendCodePoint(cp);
        }
        String cleaned = sb.toString().trim();
        int length = cleaned.codePointCount(0, cleaned.length());
        return length >= 1 && length <= MAX_NICKNAME_LENGTH ? cleaned : fallback;
    }

    /**
     * NFKC（全角转半角）→ 小写 → 去空白、分隔符 ·._-*、零宽与控制字符。
     * （对应 TS 的 STRIP = /[\s\p{Cc}​-‏⁠﻿·._\-*]/gu）
     */
    public static String normalizeForBlocklist(String s) {
        String nfkc = Normalizer.normalize(s, Normalizer.Form.NFKC).toLowerCase();
        StringBuilder sb = new StringBuilder(nfkc.length());
        nfkc.codePoints().forEach(cp -> {
            if (isStripCodePoint(cp)) return;
            sb.appendCodePoint(cp);
        });
        return sb.toString();
    }

    private static boolean isStripCodePoint(int cp) {
        if (Character.isWhitespace(cp) || Character.isSpaceChar(cp) || Character.isISOControl(cp)) return true;
        // ​-‏ ⁠ ﻿ 零宽；· 间隔号；._-* 分隔符
        if (cp >= 0x200B && cp <= 0x200F) return true;
        if (cp == 0x2060 || cp == 0xFEFF || cp == 0x00B7) return true;
        return cp == '.' || cp == '_' || cp == '-' || cp == '*';
    }

    public static boolean isNicknameBlocked(String nickname) {
        String n = normalizeForBlocklist(nickname);
        for (String p : RESERVED_PREFIXES) if (n.startsWith(p)) return true;
        for (String w : RESERVED_CONTAINS) if (n.contains(w)) return true;
        for (String w : PROFANITY) if (n.contains(w)) return true;
        return false;
    }
}
