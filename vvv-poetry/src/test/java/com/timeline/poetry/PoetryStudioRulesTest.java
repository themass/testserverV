package com.timeline.poetry;

import com.timeline.poetry.domain.PoetryStudioRules;
import com.timeline.poetry.domain.PoetryStudioRules.LocatorState;
import org.junit.jupiter.api.Test;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;

/** 纯规则测试，不需要数据库。 */
class PoetryStudioRulesTest {

    private static boolean accepted(String reviewer) { return PoetryStudioRules.reviewerProblems(reviewer).isEmpty(); }

    @Test void realNamesIncludingPinyinWithAiAreAccepted() {
        // "ai" 子串匹配会误杀这些；规则只按词/连写/角色词判断。
        for (String name : List.of("Zhang Wei", "Wang Ai", "Lai", "Bai Juyi", "Kai Chen", "Ai Weiwei", "Cai Yun", "Li-Ai", "Kai-Ling Chen",
                "张伟", "李 白", "Talbot", "McPherson", "Willmott", "Botha", "Mary O'Brien"))
            assertTrue(accepted(name), () -> name + " should be accepted but got " + PoetryStudioRules.reviewerProblems(name));
    }

    @Test void machineLookingSignaturesAreRejectedCaseInsensitively() {
        for (String name : List.of("agent", "Agent-1", "DEERFLOW", "deerflow-agent", "DeerFlow", "System Admin", "mcp", "MCP-server", "LLM",
                "ReviewerLLM", "MyBot", "bot", "chatbot", "AI", "ai", "Ai", "Claude AI", "AI Reviewer", "Ai Reviewer", "ai-reviewer", "reviewer_ai",
                "AI助手", "智能体审核", "机器人", "系统管理员"))
            assertFalse(accepted(name), () -> name + " should be rejected");
    }

    @Test void lengthAndEmptinessRules() {
        assertFalse(accepted(null));
        assertFalse(accepted(""));
        assertFalse(accepted("   "));
        assertFalse(accepted("\u200B\u200B"));      // 只有零宽字符
        assertFalse(accepted("x"));                  // 1 个字符
        assertTrue(accepted("Li"));                  // 恰好 2 个
        assertTrue(accepted("a".repeat(2) + "b".repeat(98)));    // 100
        assertFalse(accepted("a".repeat(101)));
        assertFalse(accepted("Zhang\u0007Wei"));     // 控制字符
        assertEquals("Zhang Wei", PoetryStudioRules.cleanReviewer("  Zhang\u200B   Wei  "));
    }

    @Test void publicationGateReviewerRulesStillApply() {
        for (String name : List.of("DEMO reviewer", "demo-1", "live-probe", "root", "NULL"))
            assertFalse(accepted(name), () -> name + " should be rejected");
    }

    @Test void documentedKnownLimitations() {
        // 子串 agent 会误伤 Reagent 这类罕见姓氏；小写加连字符的 "li-ai" 会被当成机器署名。接受这个代价，见 docs/studio-governance-api.md。
        assertFalse(accepted("Reagent"));
        assertFalse(accepted("li-ai"));
        // 已知漏判：不含角色词、不大写、不连写的 "Ai" 前缀机器署名(例如 "Ai Claude")会通过。
        assertTrue(accepted("Ai Claude"));
    }

    @Test void locatorStates() {
        for (String v : new String[]{null, "", "   ", "\u200B", "\u00A0"})
            assertEquals(LocatorState.MISSING, PoetryStudioRules.locatorState(v), () -> "[" + v + "]");
        for (String v : new String[]{"待核查", "待人工核对：卷次", "未核对", "xx待核查yy", "TBD", "tbd", "  TBD  ", "页码 TBD", "DEMO-1", "演练", "-", "…", "n/a", "N/A", "无", "暂无"})
            assertEquals(LocatorState.PLACEHOLDER, PoetryStudioRules.locatorState(v), () -> "[" + v + "]");
        for (String v : new String[]{"《资治通鉴》卷二百一十八", "卷二十五 第12页", "p. 123", "vol. 3, pp. 10-12", "第3册 第45页"})
            assertEquals(LocatorState.SET, PoetryStudioRules.locatorState(v), () -> "[" + v + "]");
    }

    @Test void locatorProblemMessages() {
        assertNotNull(PoetryStudioRules.locatorProblem(null));
        assertNotNull(PoetryStudioRules.locatorProblem(""));
        assertNotNull(PoetryStudioRules.locatorProblem("   "));
        assertNotNull(PoetryStudioRules.locatorProblem("待核查"));
        assertNotNull(PoetryStudioRules.locatorProblem("TBD"));
        assertNotNull(PoetryStudioRules.locatorProblem("a\u0007b"));
        assertNull(PoetryStudioRules.locatorProblem("卷一 第1页"));
        assertNull(PoetryStudioRules.locatorProblem("卷".repeat(300)));           // 按码点计 300
        assertNotNull(PoetryStudioRules.locatorProblem("卷".repeat(301)));
        assertTrue(PoetryStudioRules.locatorProblem("卷".repeat(301)).contains("300"));
    }

    @Test void roleSets() {
        assertEquals(java.util.Set.of("HISTORICAL_REVIEWER", "PLATFORM_ADMIN"), PoetryStudioRules.SOURCE_REVIEW_ROLES);
        assertTrue(PoetryStudioRules.ITEM_REVIEW_ROLES.containsAll(PoetryStudioRules.SOURCE_REVIEW_ROLES));
        assertTrue(PoetryStudioRules.ITEM_REVIEW_ROLES.contains("CONTENT_EDITOR"));
        assertFalse(PoetryStudioRules.SOURCE_REVIEW_ROLES.contains("CONTENT_EDITOR"));
        assertFalse(PoetryStudioRules.ITEM_REVIEW_ROLES.contains("RELEASE_MANAGER"));
    }
}
