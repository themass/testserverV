package com.timeline.vpn.photosolve.model;

import lombok.Data;

import java.util.ArrayList;
import java.util.List;

/**
 * 拍照解题的统一响应结构（客户端 docs/design/photo-solve-design.md 第 3 节）。
 *
 * 只有 data 部分放在这里；外层仍用项目统一的 {@link com.timeline.vpn.model.vo.JsonResult}
 * （errno/data/error），所以客户端复用 :network 现有的解析与登录态处理，不需要新的信封。
 *
 * **兼容性约定**：字段只增不改不删。客户端必须忽略未知字段。
 */
@Data
public class PhotoSolveResponse {

    /** 本次请求的 id，客户端用于日志、反馈、去重。 */
    private String requestId;

    /** 实际调用的模型标识（例如豆包的 endpoint id），排查用。 */
    private String providerUsed;

    /** 服务端判定的学科：math / physics / chemistry / english / other。 */
    private String subject;

    /** 图片里没有可解的题目时为 false。客户端据此提示「没找到题目」。 */
    private boolean questionFound = true;

    /** 题目列表：一张图里可能有多个小题，单题时长度为 1。 */
    private List<Question> questions = new ArrayList<>();

    /** 预留扩展位，客户端忽略。 */
    private Object extensions;

    @Data
    public static class Question {
        /** 从 1 开始的序号，与图片中的题目顺序对应。 */
        private int index;

        /** 题干原文（纯文本，公式用 $...$ 包住）。 */
        private String text;

        /** 题干的 LaTeX 版本，公式较多时比 text 更准确；没有则为 null。 */
        private String latex;

        /** 最终答案（纯文本）。 */
        private String finalAnswer;

        /** 最终答案的 LaTeX；没有则为 null。 */
        private String finalAnswerLatex;

        /** 解题步骤。 */
        private List<Step> steps = new ArrayList<>();

        /** 模型的把握程度 0..1；模型没有给出时为 null。 */
        private Double confidence;
    }

    @Data
    public static class Step {
        private int index;

        /** 这一步在做什么、为什么。 */
        private String text;

        /** 这一步用到的公式（可选）。 */
        private String latex;
    }
}
