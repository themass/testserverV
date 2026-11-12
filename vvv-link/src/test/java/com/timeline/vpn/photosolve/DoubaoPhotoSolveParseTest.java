package com.timeline.vpn.photosolve;

import com.timeline.vpn.photosolve.model.PhotoSolveResponse;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** 模型原始输出 → PhotoSolveResponse 的完整解析链路（不调网络）。 */
class DoubaoPhotoSolveParseTest {

    private final DoubaoPhotoSolveProvider provider = new DoubaoPhotoSolveProvider();

    @Test
    void wellFormedOutputKeepsLatexAndThinking() {
        String raw = "{\"questionFound\":true,\"subject\":\"math\",\"questions\":[{\"index\":1,"
                + "\"text\":\"解方程 $x^2-5x+6=0$\",\"latex\":\"\","
                + "\"thinking\":\"二次方程，十字相乘；注意两个根。\","
                + "\"steps\":[{\"index\":1,\"text\":\"因式分解 $(x-2)(x-3)=0$\",\"latex\":\"\"}],"
                + "\"finalAnswer\":\"$x_1=2,\\\\ x_2=3$\",\"finalAnswerLatex\":\"\",\"confidence\":0.9}]}";
        PhotoSolveResponse r = provider.parse(raw, "req-1");
        assertTrue(r.isQuestionFound());
        PhotoSolveResponse.Question q = r.getQuestions().get(0);
        assertEquals("二次方程，十字相乘；注意两个根。", q.getThinking());
        assertEquals("$x_1=2,\\ x_2=3$", q.getFinalAnswer());
    }

    @Test
    void singleBackslashFracInRealModelOutputIsPreserved() {
        // 模型漏写了一个反斜杠：以前 \frac 会被吃成「换页符 + rac」，且不报错
        String raw = "{\"questionFound\":true,\"subject\":\"math\",\"questions\":[{\"index\":1,"
                + "\"text\":\"求 $\\frac{1}{2}+\\frac{1}{3}$\",\"thinking\":\"通分\","
                + "\"steps\":[{\"index\":1,\"text\":\"通分得 $\\frac{3}{6}+\\frac{2}{6}=\\frac{5}{6}$\"}],"
                + "\"finalAnswer\":\"$\\frac{5}{6}$\"}]}";
        PhotoSolveResponse r = provider.parse(raw, "req-2");
        PhotoSolveResponse.Question q = r.getQuestions().get(0);
        assertEquals("求 $\\frac{1}{2}+\\frac{1}{3}$", q.getText());
        assertEquals("$\\frac{5}{6}$", q.getFinalAnswer());
        assertFalse(q.getText().contains("\f"), "formfeed means \\f was eaten");
    }

    @Test
    void sqrtOutputThatUsedToThrowNowParses() {
        String raw = "{\"questionFound\":true,\"questions\":[{\"index\":1,\"text\":\"化简 $\\sqrt{12}$\","
                + "\"steps\":[],\"finalAnswer\":\"$2\\sqrt{3}$\"}]}";
        PhotoSolveResponse r = provider.parse(raw, "req-3");
        assertTrue(r.isQuestionFound());
        assertEquals("$2\\sqrt{3}$", r.getQuestions().get(0).getFinalAnswer());
        assertEquals("", r.getQuestions().get(0).getThinking());
    }

    @Test
    void fencedJsonWithTextAroundIsStillExtracted() {
        String raw = "好的，答案如下：\n```json\n{\"questionFound\":true,\"questions\":[{\"index\":1,"
                + "\"text\":\"1+1\",\"finalAnswer\":\"2\"}]}\n```\n希望有帮助";
        assertEquals("2", provider.parse(raw, "req-4").getQuestions().get(0).getFinalAnswer());
    }

    @Test
    void notAQuestionYieldsEmptyList() {
        PhotoSolveResponse r = provider.parse("{\"questionFound\":false,\"questions\":[]}", "req-5");
        assertFalse(r.isQuestionFound());
        assertTrue(r.getQuestions().isEmpty());
    }
}
