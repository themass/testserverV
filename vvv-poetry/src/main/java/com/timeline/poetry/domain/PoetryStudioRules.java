package com.timeline.poetry.domain;

import java.text.Normalizer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.regex.Pattern;

/**
 * Poetry Studio 人工写入口的纯规则：署名、角色、locator 状态。不依赖数据库，便于单测。
 *
 * <p>署名规则只是"减速带"，不是身份认证(Studio 没有登录，见契约 D8)。真正的控制是：独立令牌 + 角色白名单 + 审计表。
 * 因此这里的取舍是"尽量不误伤真实人名，同时拦住明显的机器署名"，并在文档里写明已知漏判。
 */
public final class PoetryStudioRules {
    private PoetryStudioRules() {}

    /** 核验来源 / 填 locator 只允许这两个角色。 */
    public static final Set<String> SOURCE_REVIEW_ROLES = Set.of("HISTORICAL_REVIEWER", "PLATFORM_ADMIN");
    /** 逐项评审允许的角色(契约 §3.2 的三个角色)。 */
    public static final Set<String> ITEM_REVIEW_ROLES = Set.of("HISTORICAL_REVIEWER", "PLATFORM_ADMIN", "CONTENT_EDITOR");

    public static final int REVIEWER_MIN = 2;
    public static final int REVIEWER_MAX = 100;
    public static final int LOCATOR_MAX = 300;
    public static final int EXCERPT_MAX = 4000;
    public static final int NOTE_MAX = 2000;

    public static final String ID_PATTERN = "[A-Za-z0-9][A-Za-z0-9_-]{1,127}";

    public enum LocatorState { MISSING, PLACEHOLDER, SET }

    // ------------------------------------------------------------------ locator

    private static final Pattern INVISIBLE = Pattern.compile("[\\u200B-\\u200D\\u2060\\uFEFF]");
    private static final Pattern CONTROL = Pattern.compile("\\p{Cntrl}");
    private static final Pattern HAS_CONTENT = Pattern.compile("[\\p{L}\\p{N}]");
    private static final Pattern TBD_WORD = Pattern.compile("(?i)(^|[^\\p{L}\\p{N}])tbd($|[^\\p{L}\\p{N}])");
    /** 整串等于这些词也算占位(比较前已小写、去首尾空白)。 */
    private static final Set<String> FILLER = Set.of("todo", "n/a", "na", "none", "null", "无", "暂无", "略", "同上待查");

    /** 去掉零宽字符、把不间断空格当空格、去首尾空白。locator 入库用这个结果。 */
    public static String normalizeText(String raw) {
        if (raw == null) return null;
        return INVISIBLE.matcher(raw.replace('\u00A0', ' ')).replaceAll("").strip();
    }

    /**
     * 与 audit_integrity_checks.sql 的 C5_citation_locator_placeholder_on_published_claim 保持同一口径
     * (以"待"开头，或含 待核查/待人工/未核对/DEMO/演练)，再加契约要求的 TBD 与纯空白/纯标点。
     * 这样"本接口接受的 locator"以后不会被发布前核查拦下。
     */
    public static LocatorState locatorState(String raw) {
        String s = normalizeText(raw);
        if (s == null || s.isEmpty()) return LocatorState.MISSING;
        String upper = s.toUpperCase(Locale.ROOT);
        if (s.startsWith("待") || s.contains("待核查") || s.contains("待人工") || s.contains("未核对")
                || upper.contains("DEMO") || s.contains("演练")) return LocatorState.PLACEHOLDER;
        if (TBD_WORD.matcher(s).find()) return LocatorState.PLACEHOLDER;
        if (FILLER.contains(s.toLowerCase(Locale.ROOT))) return LocatorState.PLACEHOLDER;
        if (!HAS_CONTENT.matcher(s).find()) return LocatorState.PLACEHOLDER; // 只有标点/符号
        return LocatorState.SET;
    }

    /** 写入口用：返回 null 表示可接受，否则是给人看的原因。 */
    public static String locatorProblem(String raw) {
        if (raw == null) return "locator is required";
        String s = normalizeText(raw);
        if (s.isEmpty()) return "locator must not be empty or whitespace";
        if (CONTROL.matcher(s).find()) return "locator must not contain control characters";
        if (s.codePointCount(0, s.length()) > LOCATOR_MAX) return "locator is longer than " + LOCATOR_MAX + " characters";
        if (locatorState(s) != LocatorState.SET)
            return "locator is a placeholder (待核查/待人工/未核对/TBD/DEMO/演练 or no real content); write the real volume/page/section";
        return null;
    }

    // ------------------------------------------------------------------ reviewer signature

    private static final Pattern NON_ALNUM = Pattern.compile("[^\\p{L}\\p{N}]+");
    /** 驼峰/字母数字边界：DeerFlow→Deer|Flow，LLMReviewer→LLM|Reviewer，ai2→ai|2。CJK 无大小写，不会被切开。 */
    private static final Pattern HUMP = Pattern.compile(
        "(?<=\\p{Ll})(?=\\p{Lu})|(?<=\\p{Lu})(?=\\p{Lu}\\p{Ll})|(?<=\\p{L})(?=\\p{N})|(?<=\\p{N})(?=\\p{L})");
    /** 小写 "ai" 与别的词用连接符粘在一起：ai-reviewer / reviewer_ai / ai.bot。 */
    private static final Pattern JOINED_AI = Pattern.compile(
        "(?<![\\p{L}\\p{N}])ai(?=[-_./:@])|(?<=[-_./:@])ai(?![\\p{L}\\p{N}])");

    /** 足够长、误伤概率很低，直接按子串拒绝(忽略大小写)。 */
    private static final List<String> SUBSTRING_MARKERS = List.of("agent", "deerflow", "system");
    /** 中文机器身份词。 */
    private static final List<String> CJK_MARKERS = List.of("智能体", "机器人", "人工智能", "大模型", "系统", "助手");
    /** 整词(按分词后的 token)等于这些才拒绝；不做前后缀匹配，避免误伤 Talbot、Botha、McPherson、Willmott。 */
    private static final Set<String> TOKEN_MARKERS = Set.of("mcp", "llm", "bot", "bots", "chatbot", "autobot");
    /** 与 "ai" token 同时出现就判为机器署名：AI Reviewer / Ai assistant。 */
    private static final Set<String> AI_ROLE_WORDS = Set.of("reviewer", "assistant", "helper", "copilot", "model", "gpt");

    /** 归一化后的署名：去零宽/首尾空白，内部连续空白折成一个空格。 */
    public static String cleanReviewer(String raw) {
        String s = normalizeText(raw);
        return s == null ? null : s.replaceAll("\\s+", " ");
    }

    /**
     * 署名问题列表，空表示可接受。规则：
     * <ol>
     *   <li>必填，去零宽字符/首尾空白后 2–100 个字符(按码点)，不含控制字符。</li>
     *   <li>含 agent / deerflow / system 子串(忽略大小写)、中文机器身份词，拒绝。</li>
     *   <li>mcp / llm / bot(含 chatbot) 只在作为<b>完整词</b>出现时拒绝；词由非字母数字字符与驼峰边界切分。</li>
     *   <li>"ai" 不做子串匹配，否则 Lai、Bai、Kai、Cai 等拼音人名全部误杀。只在三种情形拒绝：
     *       整个署名就是 ai；写成大写 AI 的独立词且署名里还有小写字母(如 "Claude AI")；小写 ai 与别的词用 -_./:@ 连写，
     *       或与 reviewer/assistant/gpt 等角色词同时出现(如 "ai-reviewer"、"AI Assistant")。
     *       因此 "Wang Ai"、"Lai"、"Ai Weiwei" 通过；已知漏判："Ai" 单独作为姓名前缀又不带角色词的机器署名。</li>
     *   <li>另按 PublicationGate.reviewerProblems 拒绝 DEMO 前缀与 system/root/null/live-probe。</li>
     * </ol>
     */
    public static List<String> reviewerProblems(String raw) {
        List<String> problems = new ArrayList<>();
        if (raw == null || normalizeText(raw).isEmpty()) {
            problems.add("reviewer is required");
            return problems;
        }
        String cleaned = cleanReviewer(raw);
        int length = cleaned.codePointCount(0, cleaned.length());
        if (length < REVIEWER_MIN || length > REVIEWER_MAX)
            problems.add("reviewer must be " + REVIEWER_MIN + "-" + REVIEWER_MAX + " characters");
        if (CONTROL.matcher(cleaned).find()) problems.add("reviewer must not contain control characters");

        String folded = Normalizer.normalize(cleaned, Normalizer.Form.NFKC);
        String lower = folded.toLowerCase(Locale.ROOT);
        for (String marker : SUBSTRING_MARKERS)
            if (lower.contains(marker)) { problems.add("reviewer looks like a machine identity (" + marker + "); sign with a real person's name"); break; }
        for (String marker : CJK_MARKERS)
            if (folded.contains(marker)) { problems.add("reviewer looks like a machine identity (" + marker + "); sign with a real person's name"); break; }

        List<String> tokens = tokens(folded);
        for (String token : tokens)
            if (TOKEN_MARKERS.contains(token.toLowerCase(Locale.ROOT))) {
                problems.add("reviewer looks like a machine identity (" + token.toLowerCase(Locale.ROOT) + "); sign with a real person's name");
                break;
            }
        if (looksLikeAi(folded, lower, tokens))
            problems.add("reviewer looks like a machine identity (ai); sign with a real person's name");

        problems.addAll(PublicationGate.reviewerProblems(cleaned));
        return List.copyOf(problems);
    }

    private static boolean looksLikeAi(String folded, String lower, List<String> tokens) {
        String lettersOnly = NON_ALNUM.matcher(lower).replaceAll("");
        if (lettersOnly.equals("ai")) return true;
        boolean hasLowercaseLetter = folded.chars().anyMatch(Character::isLowerCase);
        boolean anyAiToken = false;
        boolean roleWord = false;
        for (String token : tokens) {
            if (token.equals("AI") && hasLowercaseLetter) return true;
            if (token.equalsIgnoreCase("ai")) anyAiToken = true;
            if (AI_ROLE_WORDS.contains(token.toLowerCase(Locale.ROOT))) roleWord = true;
        }
        if (anyAiToken && roleWord) return true;
        return JOINED_AI.matcher(folded).find();
    }

    private static List<String> tokens(String folded) {
        List<String> out = new ArrayList<>();
        for (String piece : NON_ALNUM.split(folded)) {
            if (piece.isEmpty()) continue;
            out.addAll(Arrays.stream(HUMP.split(piece)).filter(t -> !t.isEmpty()).toList());
        }
        return out;
    }
}
