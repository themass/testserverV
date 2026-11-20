package com.timeline.game.domain;

import java.util.List;
import java.util.Map;

/**
 * 对局规则参数、预设与校验（TS packages/shared/src/ruleset.ts 直译）。
 * 纯数据与纯函数。
 */
public final class Ruleset {

    private Ruleset() {}

    public static final int BOARD_MIN = 6;
    public static final int BOARD_MAX = 16;
    public static final int PLANE_HARD_MAX = 6;
    public static final double MAX_DENSITY = 0.3;
    public static final List<Integer> TURN_SECONDS = List.of(10, 15, 20, 30, 45, 60);

    public record RuleSet(int boardSize, int planeCount, int turnSeconds, boolean hintAllowed) {}

    public enum Capacity {
        C2(2), C3(3), C4(4);
        public final int n;
        Capacity(int n) { this.n = n; }
    }

    public enum PresetId { BEGINNER, STANDARD, ADVANCED, EXPERT }

    public static final Map<PresetId, RuleSet> PRESETS = Map.of(
        PresetId.BEGINNER, new RuleSet(8, 1, 30, true),
        PresetId.STANDARD, new RuleSet(10, 1, 20, true),
        PresetId.ADVANCED, new RuleSet(12, 2, 20, false),
        PresetId.EXPERT, new RuleSet(14, 3, 15, false));

    public static final Map<PresetId, String> PRESET_LABELS = Map.of(
        PresetId.BEGINNER, "入门", PresetId.STANDARD, "标准",
        PresetId.ADVANCED, "进阶", PresetId.EXPERT, "高手");

    /** 给定边长下允许的最大飞机数：每架占 9 格，总占比不超过 MAX_DENSITY。 */
    public static int maxPlanes(int boardSize) {
        return Math.min(PLANE_HARD_MAX, (int) Math.floor(MAX_DENSITY * boardSize * boardSize / 9.0));
    }

    public enum ValidateReason { SHAPE, BOARD_SIZE, PLANE_COUNT, TURN_SECONDS }

    public record ValidateResult(boolean ok, RuleSet rules, ValidateReason reason) {
        static ValidateResult ok(RuleSet rules) { return new ValidateResult(true, rules, null); }
        static ValidateResult fail(ValidateReason reason) { return new ValidateResult(false, null, reason); }
    }

    /**
     * 校验 Jackson 解出的原始值是否为合法 RuleSet（对齐 TS validateRuleSet 的检查顺序与语义：
     * shape → boardSize → planeCount → turnSeconds），返回只含四个字段的新对象。
     * 入参是已解析 JSON 的原始形态：数字为 Number、布尔为 Boolean、缺失为 null——由调用方
     * 从 JsonNode 转换后传入（见 api 层 GameJson），本层保持零依赖。
     */
    public static ValidateResult validateRuleSet(Object rawBoardSize, Object rawPlaneCount,
                                                 Object rawTurnSeconds, Object rawHintAllowed, boolean shapeOk) {
        if (!shapeOk) return ValidateResult.fail(ValidateReason.SHAPE);
        if (!(rawHintAllowed instanceof Boolean)) return ValidateResult.fail(ValidateReason.SHAPE);
        if (!(rawBoardSize instanceof Integer b) || b < BOARD_MIN || b > BOARD_MAX) {
            return ValidateResult.fail(ValidateReason.BOARD_SIZE);
        }
        if (!(rawPlaneCount instanceof Integer p) || p < 1 || p > maxPlanes(b)) {
            return ValidateResult.fail(ValidateReason.PLANE_COUNT);
        }
        if (!(rawTurnSeconds instanceof Integer t) || !TURN_SECONDS.contains(t)) {
            return ValidateResult.fail(ValidateReason.TURN_SECONDS);
        }
        return ValidateResult.ok(new RuleSet(b, p, t, (Boolean) rawHintAllowed));
    }

    /** 布阵阶段时长（秒）：30 + 15 × 飞机数。 */
    public static int placeSeconds(RuleSet rules) {
        return 30 + 15 * rules.planeCount();
    }

    /** 飞机格数占棋盘总格数的比例。 */
    public static double planeDensity(RuleSet rules) {
        return rules.planeCount() * 9.0 / (rules.boardSize() * rules.boardSize());
    }
}
