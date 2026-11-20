package com.timeline.game.domain;

import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/** 自动摆放单测（镜像 TS placement.test.ts 全部预期）。 */
class PlacementTest {

    @Test
    void 每个边长每个合法飞机数都摆得下且合法() {
        for (int n = Ruleset.BOARD_MIN; n <= Ruleset.BOARD_MAX; n++) {
            for (int k = 1; k <= Ruleset.maxPlanes(n); k++) {
                List<Rules.Cell> heads = Placement.autoPlace(n, k, Mulberry32.of(n * 100 + k));
                assertTrue(Rules.checkPlacement(heads, n, k).ok(), "n=" + n + " k=" + k);
            }
        }
    }

    @Test
    void 随机源恒返回零点九九九时仍有解() {
        assertTrue(Rules.checkPlacement(Placement.autoPlace(16, 6, () -> 0.999), 16, 6).ok());
    }

    @Test
    void 同一随机种子结果确定() {
        assertEquals(Placement.autoPlace(12, 2, Mulberry32.of(7)), Placement.autoPlace(12, 2, Mulberry32.of(7)));
    }
}
