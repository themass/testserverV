package com.timeline.vpn.photosolve;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** 模型输出的 LaTeX 反斜杠与 JSON 转义冲突的各种写法。 */
class PhotoSolveJsonRepairTest {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    /** 把 {"t": "<body>"} 修复并解析，返回 t 的值。body 里写的是「模型实际输出的原文」。 */
    private static String parseT(String body) throws Exception {
        String repaired = PhotoSolveJsonRepair.repair("{\"t\":\"" + body + "\"}");
        JsonNode node = MAPPER.readTree(repaired);
        return node.get("t").asText();
    }

    @Test
    void correctlyDoubledBackslashesAreLeftAlone() throws Exception {
        assertEquals("$\\frac{1}{2}$", parseT("$\\\\frac{1}{2}$"));
    }

    // ---- 最危险的一类：合法转义，不报错但公式被吃掉 ----

    @Test
    void singleBackslashFracIsNotEatenAsFormFeed() throws Exception {
        assertEquals("$\\frac{1}{2}$", parseT("$\\frac{1}{2}$"));
    }

    @Test
    void textCommandIsNotEatenAsTab() throws Exception {
        assertEquals("$\\text{cm}$", parseT("$\\text{cm}$"));
    }

    @Test
    void rightAndNeqAndBetaAndThetaSurvive() throws Exception {
        assertEquals("$\\left(x\\right)$", parseT("$\\left(x\\right)$"));
        assertEquals("$a\\neq b$", parseT("$a\\neq b$"));
        assertEquals("$\\beta+\\theta$", parseT("$\\beta+\\theta$"));
        assertEquals("$a\\times b$", parseT("$a\\times b$"));
        assertEquals("$\\nu$", parseT("$\\nu$"));
        assertEquals("$\\rho$", parseT("$\\rho$"));
    }

    // ---- 非法转义：不修的话整个解析直接抛异常 ----

    @Test
    void sqrtPiAlphaAreIllegalEscapesAndGetFixed() throws Exception {
        assertEquals("$\\sqrt{3}$", parseT("$\\sqrt{3}$"));
        assertEquals("$\\pi r^2$", parseT("$\\pi r^2$"));
        assertEquals("$\\alpha\\cdot\\sum$", parseT("$\\alpha\\cdot\\sum$"));
    }

    @Test
    void parenthesesDelimitersAreFixed() throws Exception {
        assertEquals("\\(x\\)", parseT("\\(x\\)"));
        assertEquals("\\[x\\]", parseT("\\[x\\]"));
    }

    // ---- 真正的转义必须保留 ----

    @Test
    void realNewlineAndTabEscapesStayEscapes() throws Exception {
        assertEquals("第一行\n第二行", parseT("第一行\\n第二行"));
        assertEquals("a\tb", parseT("a\\tb"));
    }

    @Test
    void newlineFollowedByPlainWordIsStillANewline() throws Exception {
        assertEquals("结果\nThe answer", parseT("结果\\nThe answer"));
        assertEquals("结果\n答案是2", parseT("结果\\n答案是2"));
    }

    @Test
    void escapedQuoteAndSlashAndUnicodeAreKept() throws Exception {
        assertEquals("他说\"好\"", parseT("他说\\\"好\\\""));
        assertEquals("a/b", parseT("a\\/b"));
        assertEquals("中", parseT("\\u4e2d"));
    }

    @Test
    void unicodeEscapeNeedsFourHexDigitsOtherwiseItIsLatexUnderline() throws Exception {
        assertEquals("$\\underline{x}$", parseT("$\\underline{x}$"));
    }

    @Test
    void mixedContentInOneString() throws Exception {
        String body = "解：$x=\\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}$\\n再检验 $\\text{cm}$";
        assertEquals("解：$x=\\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}$\n再检验 $\\text{cm}$", parseT(body));
    }

    @Test
    void backslashesOutsideStringsAreNotTouched() {
        String json = "{\"a\":1,\"b\":[1,2]}";
        assertEquals(json, PhotoSolveJsonRepair.repair(json));
    }

    @Test
    void repairIsIdempotent() {
        String once = PhotoSolveJsonRepair.repair("{\"t\":\"$\\frac{1}{2}$ \\sqrt{3} \\n\"}");
        assertEquals(once, PhotoSolveJsonRepair.repair(once));
    }

    @Test
    void nullAndNoBackslashPassThrough() {
        assertNull(PhotoSolveJsonRepair.repair(null));
        assertEquals("{}", PhotoSolveJsonRepair.repair("{}"));
    }

    @Test
    void trailingLoneBackslashDoesNotCrash() {
        assertTrue(PhotoSolveJsonRepair.repair("{\"t\":\"abc\\").length() > 0);
    }
}
