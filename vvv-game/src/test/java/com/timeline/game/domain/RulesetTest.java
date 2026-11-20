package com.timeline.game.domain;

import org.junit.jupiter.api.Test;

import java.util.Map;

import static com.timeline.game.domain.Ruleset.*;
import static org.junit.jupiter.api.Assertions.*;

/** 规则校验单测（镜像 TS packages/shared/test/ruleset.test.ts 的全部预期）。 */
class RulesetTest {

    /** 把 RuleSet 摊平喂给校验函数（api 层从 JsonNode 提取同构四元组）。 */
    static ValidateResult check(RuleSet r) {
        return validateRuleSet(r.boardSize(), r.planeCount(), r.turnSeconds(), r.hintAllowed(), true);
    }

    static ValidateResult checkRaw(Object b, Object p, Object t, Object h) {
        return validateRuleSet(b, p, t, h, true);
    }

    @Test
    void maxPlanes与spec表格一致() {
        int[][] table = {{6, 1}, {7, 1}, {8, 2}, {9, 2}, {10, 3}, {11, 4}, {12, 4}, {13, 5}, {14, 6}, {15, 6}, {16, 6}};
        for (int[] row : table) assertEquals(row[1], maxPlanes(row[0]), "boardSize=" + row[0]);
    }

    @Test
    void 上限总能被三三整齐排列放下() {
        for (int n = BOARD_MIN; n <= BOARD_MAX; n++) {
            assertTrue(maxPlanes(n) <= (n / 3) * (n / 3), "boardSize=" + n);
        }
    }

    @Test
    void 四档预设全部合法() {
        for (RuleSet r : PRESETS.values()) assertTrue(check(r).ok());
    }

    @Test
    void 预设数值() {
        assertEquals(new RuleSet(8, 1, 30, true), PRESETS.get(PresetId.BEGINNER));
        assertEquals(new RuleSet(10, 1, 20, true), PRESETS.get(PresetId.STANDARD));
        assertEquals(new RuleSet(12, 2, 20, false), PRESETS.get(PresetId.ADVANCED));
        assertEquals(new RuleSet(14, 3, 15, false), PRESETS.get(PresetId.EXPERT));
    }

    @Test
    void 非法边长逐个报boardSize() {
        // 5/17/10.5/'10' —— 类型与范围都归 boardSize（TS 同：数字越界或类型非 number）
        for (Object bad : new Object[]{5, 17, 10.5, "10"}) {
            ValidateResult v = checkRaw(bad, 1, 20, true);
            assertFalse(v.ok());
            assertEquals(ValidateReason.BOARD_SIZE, v.reason(), "bad=" + bad);
        }
    }

    @Test
    void 飞机数越界报planeCount() {
        assertEquals(ValidateReason.PLANE_COUNT, checkRaw(10, 4, 20, true).reason()); // 10×10 最多 3 架
        assertEquals(ValidateReason.PLANE_COUNT, checkRaw(10, 0, 20, true).reason());
    }

    @Test
    void 回合时长不在列表报turnSeconds() {
        assertEquals(ValidateReason.TURN_SECONDS, checkRaw(10, 1, 25, true).reason());
    }

    @Test
    void 缺字段或非对象是shape() {
        assertFalse(validateRuleSet(null, null, null, null, false).ok());
        assertEquals(ValidateReason.SHAPE, validateRuleSet(null, null, null, null, false).reason());
        assertEquals(ValidateReason.SHAPE, checkRaw(10, null, null, null).reason());
    }

    @Test
    void hintAllowed非布尔为shape() {
        assertEquals(ValidateReason.SHAPE, checkRaw(10, 1, 20, "yes").reason());
    }

    @Test
    void 校验返回的对象只含四个字段() {
        // record 天然只有四字段；这里锁死"多余字段被丢弃"的语义由 api 层解码保证
        ValidateResult v = check(PRESETS.get(PresetId.STANDARD));
        assertTrue(v.ok());
        assertEquals(new RuleSet(10, 1, 20, true), v.rules());
    }

    @Test
    void 布阵时长与占比() {
        assertEquals(45, placeSeconds(PRESETS.get(PresetId.STANDARD)));
        assertEquals(75, placeSeconds(PRESETS.get(PresetId.EXPERT)));
        assertEquals(0.09, planeDensity(PRESETS.get(PresetId.STANDARD)), 1e-9);
    }

    @Test
    void 预设标签() {
        assertEquals(Map.of(PresetId.BEGINNER, "入门", PresetId.STANDARD, "标准",
            PresetId.ADVANCED, "进阶", PresetId.EXPERT, "高手"), PRESET_LABELS);
    }
}
