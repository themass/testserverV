package com.timeline.vpn.photosolve;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * {@link PhotoSolveJsonSalvage}：模型输出被 maxTokens 砍断时，把已写完整的部分补成合法 JSON。
 *
 * 统一判据：<b>一个字都不编</b>。
 * <ul>
 *   <li>截断落在字符串<b>值</b>里 → 保留已吐出的内容，补上收尾引号（半句话也是内容）；</li>
 *   <li>截断落在<b>数字/字面量</b>里 → 整个键值对丢掉（半个数字是错值，不是部分正确）；</li>
 *   <li>截断落在<b>键名</b>里、或停在 {@code "k":} 后面 → 这个键丢掉；</li>
 *   <li>其余只允许在末尾追加收尾符 {@code " } ] ,} 与空格。</li>
 * </ul>
 */
class PhotoSolveJsonSalvageTest {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    /** 抢救 + 反斜杠修复后解析；返回 null 表示救不回来。 */
    private static JsonNode salvageAndParse(String raw) throws Exception {
        String salvaged = PhotoSolveJsonSalvage.salvage(raw);
        if (salvaged == null) {
            return null;
        }
        return MAPPER.readTree(PhotoSolveJsonRepair.repair(salvaged));
    }

    @Test
    void completeJsonPassesThroughUnchanged() {
        String json = "{\"questionFound\":true,\"subject\":\"math\",\"questions\":["
                + "{\"index\":1,\"text\":\"1+1\",\"finalAnswer\":\"2\"}]}";
        assertEquals(json, PhotoSolveJsonSalvage.salvage(json));
    }

    @Test
    void truncatedInsideSecondQuestionKeepsTheFirstOneStructured() throws Exception {
        // 截断发生在第二题的 text 里：第一题必须整条保住（题干/答案/步骤），
        // 不能整包退化成一段纯文本——那正是 P0-5 里用户「看到一坨 JSON」的原因。
        String raw = "{\"questionFound\":true,\"subject\":\"math\",\"questions\":["
                + "{\"index\":1,\"text\":\"解方程 $x^2-5x+6=0$\",\"finalAnswer\":\"$x_1=2$,"
                + "x_2=3$\",\"steps\":[{\"index\":1,\"text\":\"因式分解\"}]},"
                + "{\"index\":2,\"text\":\"计算 $\\frac{1}{2}+";
        JsonNode root = salvageAndParse(raw);
        assertNotNull(root, "截断的 JSON 应该能救回结构");
        assertTrue(root.path("questionFound").asBoolean());
        assertEquals("math", root.path("subject").asText());
        JsonNode questions = root.path("questions");
        assertTrue(questions.isArray());
        assertEquals(2, questions.size(), "第二题的半截题干也留着，只是没有答案");
        JsonNode q1 = questions.get(0);
        assertEquals("解方程 $x^2-5x+6=0$", q1.path("text").asText());
        assertEquals("$x_1=2$,x_2=3$", q1.path("finalAnswer").asText());
        assertEquals(1, q1.path("steps").size());
        assertEquals("因式分解", q1.path("steps").get(0).path("text").asText());
    }

    @Test
    void truncatedValueStringKeepsWhatWasWritten() throws Exception {
        JsonNode root = salvageAndParse("{\"thinking\":\"先审题，已知两根之和为 5，要求");
        assertNotNull(root);
        assertEquals("先审题，已知两根之和为 5，要求", root.path("thinking").asText());
    }

    @Test
    void partialNumberOrLiteralDropsTheWholePair() throws Exception {
        JsonNode root = salvageAndParse("{\"confidence\":0.9,\"subject\":\"math\",\"score\":12");
        assertNotNull(root);
        assertEquals("math", root.path("subject").asText());
        assertEquals(0.9, root.path("confidence").asDouble(), 1e-9);
        assertTrue(root.path("score").isMissingNode(), "半截的数字是错值，不能当完整值给出去");

        JsonNode literal = salvageAndParse("{\"questionFound\":tru");
        assertNotNull(literal);
        assertTrue(literal.path("questionFound").isMissingNode());
    }

    @Test
    void danglingKeyWithNoValueIsDropped() throws Exception {
        // 截断正好停在 "finalAnswer": 之后：值还没开始，这个键整个去掉
        String raw = "{\"questionFound\":true,\"subject\":\"math\",\"finalAnswer\":";
        JsonNode root = salvageAndParse(raw);
        assertNotNull(root);
        assertEquals("math", root.path("subject").asText());
        assertTrue(root.path("finalAnswer").isMissingNode());
    }

    @Test
    void truncatedInsideKeyOrAfterOpeningBracket() throws Exception {
        assertEquals("{}", PhotoSolveJsonSalvage.salvage("{\"someKey"));

        JsonNode emptyArr = salvageAndParse("{\"questionFound\":true,\"questions\":[");
        assertNotNull(emptyArr);
        assertTrue(emptyArr.path("questions").isArray());
        assertEquals(0, emptyArr.path("questions").size());

        JsonNode obj = salvageAndParse("{\"subject\":\"math\",\"questions\":[{\"text\":\"a\"}],\"ext\":{");
        assertNotNull(obj);
        assertEquals("math", obj.path("subject").asText());
        assertTrue(obj.path("ext").isObject());
    }

    @Test
    void truncatedRightAfterBraceYieldsEmptyObject() {
        assertEquals("{}", PhotoSolveJsonSalvage.salvage("{"));
        assertEquals("{}", PhotoSolveJsonSalvage.salvage("{\"k\""));
    }

    @Test
    void escapedQuotesAndBracesInsideStringsDoNotConfuseTheScan() throws Exception {
        // 字符串里的 \" 和 } 会被朴素的括号计数误判
        String raw = "{\"questionFound\":true,\"text\":\"他说\\\"好\\\" }, 继续 { 花括号\","
                + "\"finalAnswer\":\"2\",\"tail\":\"截在这";
        JsonNode root = salvageAndParse(raw);
        assertNotNull(root);
        assertEquals("他说\"好\" }, 继续 { 花括号", root.path("text").asText());
        assertEquals("2", root.path("finalAnswer").asText());
        assertEquals("截在这", root.path("tail").asText());
    }

    @Test
    void loneTrailingBackslashIsDroppedBeforeClosingQuote() throws Exception {
        // 半截反斜杠若原样留着，补上引号就成了 \" —— 引号被转义，整包又坏了
        JsonNode root = salvageAndParse("{\"text\":\"化简 $\\sqrt{3}$ 得 $\\");
        assertNotNull(root);
        assertEquals("化简 $\\sqrt{3}$ 得 $", root.path("text").asText());
    }

    @Test
    void truncatedInsideCodeFenceIsSalvagedFromTheFirstBrace() throws Exception {
        String raw = "```json\n{\"questionFound\":true,\"questions\":[{\"index\":1,"
                + "\"text\":\"1+1\",\"finalAnswer\":\"2\"},{\"index\":2,\"text\":\"2+2";
        JsonNode root = salvageAndParse(raw);
        assertNotNull(root, "围栏没收尾也要能救");
        assertEquals(2, root.path("questions").size());
        assertEquals("2", root.path("questions").get(0).path("finalAnswer").asText());
        assertEquals("2+2", root.path("questions").get(1).path("text").asText());
    }

    @Test
    void leadingProseBeforeJsonIsIgnored() throws Exception {
        JsonNode root = salvageAndParse("好的，我来看这道题：{\"finalAnswer\":\"x=2\",\"step\":\"先移项");
        assertNotNull(root);
        assertEquals("x=2", root.path("finalAnswer").asText());
        assertEquals("先移项", root.path("step").asText());
    }

    @Test
    void nothingSalvageableReturnsNull() {
        assertNull(PhotoSolveJsonSalvage.salvage(null));
        assertNull(PhotoSolveJsonSalvage.salvage(""));
        assertNull(PhotoSolveJsonSalvage.salvage("   "));
        assertNull(PhotoSolveJsonSalvage.salvage("抱歉，这张图片里我看不到题目。"));
    }

    @Test
    void salvageIsIdempotent() {
        String once = PhotoSolveJsonSalvage.salvage("{\"a\":1,\"b\":[{\"c\":2},{\"d\":\"ee");
        assertNotNull(once);
        assertEquals(once, PhotoSolveJsonSalvage.salvage(once));
    }

    @Test
    void salvageOnlyTruncatesAndAppendsClosers() {
        // 截断停在半截数字 `2` 上：这个数字必须去掉（半个数是错值），
        // 但除此之外只能「砍掉尾巴 + 补收尾」，已写出的字节一个都不改、不重排。
        String raw = "{\"a\":1,\"b\":[1,2";
        String salvaged = PhotoSolveJsonSalvage.salvage(raw);
        assertNotNull(salvaged);
        assertTrue(salvaged.startsWith("{\"a\":1,\"b\":[1"), "已写完整的部分必须原样保留：" + salvaged);
        String tail = salvaged.substring("{\"a\":1,\"b\":[1".length());
        assertTrue(tail.matches("[\"\\]},]*"), "尾部只允许收尾符，实际：" + tail);

        // 反过来：停在字符串值中间时，已写出的内容全部保留
        String keepAll = PhotoSolveJsonSalvage.salvage("{\"a\":1,\"b\":[1,2]");
        assertEquals("{\"a\":1,\"b\":[1,2]}", keepAll);
    }

    @Test
    void deeplyNestedTruncationClosesEveryOpenContainer() throws Exception {
        String raw = "{\"a\":{\"b\":{\"c\":[1,{\"d\":[\"x\",\"yy";
        String salvaged = PhotoSolveJsonSalvage.salvage(raw);
        assertNotNull(salvaged);
        JsonNode root = MAPPER.readTree(salvaged);
        // c 数组是 [1, {"d": [...]}]，对象在第二个元素
        JsonNode d = root.path("a").path("b").path("c").get(1).path("d");
        assertEquals(2, d.size(), "半截字符串也算内容，保留 \"yy\"");
        assertEquals("x", d.get(0).asText());
        assertEquals("yy", d.get(1).asText());
    }
}
