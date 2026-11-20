package com.timeline.game.domain;

import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Set;

import static com.timeline.game.domain.Rules.*;
import static org.junit.jupiter.api.Assertions.*;

/** 几何/弹道单测（镜像 TS geometry.test.ts + resolve-shot.test.ts + candidate-heads.test.ts 全部预期）。 */
class RulesTest {

    @Test
    void cellsOfPlane返回机头为中心的九格含机头自身() {
        List<Cell> cells = cellsOfPlane(new Cell(5, 5));
        assertEquals(9, cells.size());
        assertTrue(cells.contains(new Cell(4, 4)));
        assertTrue(cells.contains(new Cell(6, 6)));
        assertTrue(cells.contains(new Cell(5, 5)));
        assertTrue(cellsOfPlane(new Cell(3, 7)).contains(new Cell(3, 7)));
    }

    @Test
    void 合法机头范围一到位棋盘减二() {
        assertTrue(isPlacementValid(new Cell(5, 5), 10));
        assertFalse(isPlacementValid(new Cell(0, 5), 10));
        assertFalse(isPlacementValid(new Cell(9, 5), 10));
        assertFalse(isPlacementValid(new Cell(5, 0), 10));
        assertFalse(isPlacementValid(new Cell(5, 9), 10));
        assertTrue(isPlacementValid(new Cell(1, 1), 10));
        assertTrue(isPlacementValid(new Cell(8, 8), 10));
        // 小棋盘 6×6 的范围是 1..4
        assertTrue(isPlacementValid(new Cell(4, 4), 6));
        assertFalse(isPlacementValid(new Cell(5, 5), 6));
    }

    @Test
    void checkPlacement按count越界重叠顺序报错() {
        assertEquals(PlacementReason.COUNT, checkPlacement(List.of(new Cell(5, 5)), 10, 2).reason());
        // 两个机头相邻，(5,5) 与 (5,6) 的 9 格必然相交
        assertEquals(PlacementReason.OVERLAP,
            checkPlacement(List.of(new Cell(5, 5), new Cell(5, 6)), 10, 2).reason());
        assertTrue(checkPlacement(List.of(new Cell(2, 2), new Cell(6, 6)), 10, 2).ok());
        // 越界优先于重叠被报出
        assertEquals(PlacementReason.OUT_OF_BOUNDS,
            checkPlacement(List.of(new Cell(0, 0), new Cell(5, 5)), 10, 2).reason());
    }

    @Test
    void cellKey稳定且区分相邻格() {
        assertEquals("3,4", new Cell(3, 4).key());
        assertNotEquals(new Cell(4, 3).key(), new Cell(3, 4).key());
    }

    static final List<Plane> ONE = List.of(new Plane("p0", new Cell(5, 5)));

    @Test
    void resolveShot先判机头再判机身() {
        assertEquals(new ShotResolution(ShotResult.HEAD, "p0"), resolveShot(ONE, new Cell(5, 5)));
        assertEquals(new ShotResolution(ShotResult.BODY, "p0"), resolveShot(ONE, new Cell(4, 4)));
        assertEquals(new ShotResolution(ShotResult.BODY, "p0"), resolveShot(ONE, new Cell(6, 6)));
        assertEquals(new ShotResolution(ShotResult.BODY, "p0"), resolveShot(ONE, new Cell(4, 5)));
        assertEquals(new ShotResolution(ShotResult.BODY, "p0"), resolveShot(ONE, new Cell(5, 6)));
        assertEquals(ShotResult.MISS, resolveShot(ONE, new Cell(3, 5)).result());
        assertEquals(ShotResult.MISS, resolveShot(ONE, new Cell(7, 7)).result());
        // 多机时返回命中的那一架的 id
        List<Plane> two = List.of(new Plane("p0", new Cell(2, 2)), new Plane("p1", new Cell(7, 7)));
        assertEquals(new ShotResolution(ShotResult.HEAD, "p1"), resolveShot(two, new Cell(7, 7)));
        assertEquals(new ShotResolution(ShotResult.BODY, "p1"), resolveShot(two, new Cell(6, 7)));
        assertEquals(ShotResult.MISS, resolveShot(List.of(), new Cell(5, 5)).result());
    }

    @Test
    void candidateHeads收缩与交集() {
        // 10×10 的合法机头是 1..8 × 1..8 = 64 个
        assertEquals(64, candidateHeads(List.of(), 10).size());
        List<Cell> c = candidateHeads(List.of(new Cell(5, 5)), 10);
        assertEquals(8, c.size());
        assertTrue(c.contains(new Cell(4, 4)));
        assertFalse(c.contains(new Cell(5, 5))); // 机头本身不可能
        assertFalse(c.contains(new Cell(3, 5)));
        // 靠近边缘时按棋盘裁剪：(1,1) 的左上邻域只有 3 个合法机头
        List<Cell> edge = candidateHeads(List.of(new Cell(1, 1)), 10);
        assertEquals(3, edge.size());
        assertTrue(edge.contains(new Cell(2, 2)));
        assertTrue(edge.contains(new Cell(1, 2)));
        assertTrue(edge.contains(new Cell(2, 1)));
        // 两次机身命中取交集
        List<Cell> inter = candidateHeads(List.of(new Cell(4, 5), new Cell(5, 6)), 10);
        assertTrue(inter.contains(new Cell(5, 5)));
        assertTrue(inter.size() < 8);
        // 互相矛盾的命中返回空集
        assertEquals(0, candidateHeads(List.of(new Cell(1, 1), new Cell(8, 8)), 10).size());
    }

    @Test
    void 全灭判定与重复炮与未打格() {
        List<Plane> planes = List.of(new Plane("a", new Cell(2, 2)), new Plane("b", new Cell(6, 6)));
        assertFalse(isAllPlanesDestroyed(planes, List.of("a")));
        assertTrue(isAllPlanesDestroyed(planes, List.of("a", "b")));
        assertTrue(isAllPlanesDestroyed(List.of(), List.of())); // 空列表视为已结束（防御性）

        assertTrue(isRepeatShot(Set.of("3,4"), new Cell(3, 4)));
        assertFalse(isRepeatShot(Set.of("3,4"), new Cell(4, 3)));

        assertEquals(10 * 10 - 1, unshotCells(10, Set.of("0,0")).size());
    }
}
