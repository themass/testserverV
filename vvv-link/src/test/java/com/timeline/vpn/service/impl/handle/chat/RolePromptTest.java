package com.timeline.vpn.service.impl.handle.chat;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class RolePromptTest {

    @Test
    void roleTextWithPercentSignsDoesNotBreakFormatting() {
        String role = "You are a tax advisor. Typical rate is 20% and %s %d must survive verbatim.";
        String prompt = assertDoesNotThrow(() -> BaseChatHandleProxy.buildRolePrompt(role, "zh", "[user]hi"));
        assertTrue(prompt.contains("20% and %s %d must survive verbatim."));
    }

    @Test
    void keepsHistoryAndLanguageAndAllowsCodeBlocks() {
        String prompt = BaseChatHandleProxy.buildRolePrompt("ROLE", "zh-CN", "[user]hello");
        assertTrue(prompt.startsWith("ROLE"));
        assertTrue(prompt.contains("zh-CN"));
        assertTrue(prompt.endsWith("[user]hello"));
        assertFalse(prompt.contains("不使用代码块"));
    }
}
