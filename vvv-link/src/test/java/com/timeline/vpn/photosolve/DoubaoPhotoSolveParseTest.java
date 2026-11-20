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

    @Test
    void truncatedJsonFallsBackToRawTextInsteadOfNotAQuestion() {
        // maxTokens 截断：JSON 起了头但没收尾。extractJson 括号配不平返回 null，
        // 以前这里直接 questionFound=false → 客户端 40002「不是题目」。
        // 明明拍了题，却说没有题——截断是**我们**的失败，不是用户没拍题。
        // 兜底策略（见 parse 的 javadoc）应把模型吐出的部分当文本给用户。
        String raw = "{\"questionFound\":true,\"subject\":\"math\",\"questions\":[{\"index\":1,"
                + "\"text\":\"解方程 $x^2-5x+6=0$\",\"steps\":[{\"index\":1,\"text\":\"因式分解"
                + "$(x-2)(x-3)=";
        PhotoSolveResponse r = provider.parse(raw, "req-6");
        assertTrue(r.isQuestionFound(), "截断的输出不能报「不是题目」");
        assertTrue(r.getQuestions().get(0).getText().contains("解方程"));
    }

    @Test
    void truncatedJsonKeepsTheAlreadyCompleteQuestionStructured() {
        // P0-5 剩下的半个问题：上一条只是不再报「不是题目」，但用户看到的仍是**一坨 JSON 源码**
        // ——题干、答案、步骤这些结构全丢了。第一题其实已经写完整，只有第二题被砍断，
        // 应该把第一题原样还原成结构（题干/最终答案/步骤），而不是把整段原文塞进 text。
        String raw = "{\"questionFound\":true,\"subject\":\"math\",\"questions\":["
                + "{\"index\":1,\"text\":\"解方程 $x^2-5x+6=0$\",\"finalAnswer\":\"$x_1=2,\\\\ x_2=3$\","
                + "\"steps\":[{\"index\":1,\"text\":\"因式分解 $(x-2)(x-3)=0$\",\"latex\":\"\"}]},"
                + "{\"index\":2,\"text\":\"计算 $\\frac{1}{2}+\\frac{1}{3}$，先把";
        PhotoSolveResponse r = provider.parse(raw, "req-8");
        assertTrue(r.isQuestionFound());
        assertEquals("math", r.getSubject());

        // 被砍断的第二题即使留在结构里，也不能让第一题退化成纯文本
        PhotoSolveResponse.Question first = r.getQuestions().get(0);
        assertEquals(1, first.getIndex());
        assertEquals("解方程 $x^2-5x+6=0$", first.getText());
        assertFalse(first.getText().contains("questionFound"),
                "text 是题干，不是整段 JSON 源码");
        assertEquals("$x_1=2,\\ x_2=3$", first.getFinalAnswer());
        assertEquals(1, first.getSteps().size());
        assertEquals("因式分解 $(x-2)(x-3)=0$", first.getSteps().get(0).getText());
    }

    @Test
    void truncatedJsonInsideFirstQuestionStillKeepsCompletedFields() {
        // 只写完了题干和第一大步，答案与后续被砍：已完整字段必须留下，缺失字段按空处理，
        // 而不是把 JSON 源码整段当题干。
        String raw = "{\"questionFound\":true,\"subject\":\"physics\",\"questions\":[{\"index\":1,"
                + "\"text\":\"一个物体从 20m 落下\",\"steps\":[{\"index\":1,\"text\":\"用 $v^2=2gh$\"}],"
                + "\"finalAnswer\":\"$v=20\\\\,\\\\text{m/s}$\",\"thinking\":\"忽略空气阻";
        PhotoSolveResponse r = provider.parse(raw, "req-9");
        assertTrue(r.isQuestionFound());
        PhotoSolveResponse.Question q = r.getQuestions().get(0);
        assertEquals("一个物体从 20m 落下", q.getText());
        assertFalse(q.getText().contains("steps"), "text 不能是 JSON 源码");
        assertEquals("$v=20\\,\\text{m/s}$", q.getFinalAnswer());
        assertEquals(1, q.getSteps().size());
        // thinking 被砍在句子中间：半句话仍然是内容，按 salvage 的判据原样保留
        assertEquals("忽略空气阻", q.getThinking());
    }

    @Test
    void salvageOnlyRunsWhenTheJsonIsTruncatedNotWhenItIsPlainProse() {
        // 负样本：整段是话术，连 `{` 都没有——不能因为加了 salvage 就凭空造出题目结构。
        PhotoSolveResponse r = provider.parse("这道题我看不太清，能再拍一张吗？", "req-10");
        assertFalse(r.isQuestionFound());
        assertTrue(r.getQuestions().isEmpty());
    }

    @Test
    void salvagedEmptyShellFallsBackToTextInsteadOfZeroQuestions() {
        // 极端截断：模型只写出了 `{"k`，salvage 补出的是空对象 `{}`——
        // 结构里没有可用内容。此时不能返回「found=true 但 0 道题」（客户端会渲染成空白），
        // 要退回纯文本兜底，至少把原文给用户。
        PhotoSolveResponse r = provider.parse("{\"k\"", "req-11");
        assertTrue(r.isQuestionFound());
        assertEquals(1, r.getQuestions().size());
        assertTrue(r.getQuestions().get(0).getText().contains("{"));
    }

    @Test
    void proseWithoutAnyBraceStillMeansNoQuestion() {
        // 模型完全没吐 JSON（整段是话术）：保持「不是题目」，
        // 这个负样本防止上一条把语义放得太宽。
        PhotoSolveResponse r = provider.parse("抱歉，这张图片里我看不到题目。", "req-7");
        assertFalse(r.isQuestionFound());
    }
}
