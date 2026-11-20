package com.timeline.game.domain;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * 纯函数几何与弹道判定（TS packages/shared/src/rules.ts 直译）。
 * 无 IO、无时间、无随机——因此可被确定性测试。
 * 所有涉及棋盘尺寸的函数都必须接受 boardSize 参数，不得读常量（spec §四、§十五）。
 */
public final class Rules {

    private Rules() {}

    public record Cell(int row, int col) {
        public String key() { return row + "," + col; }
    }

    public record Plane(String id, Cell head) {}

    /** 一架飞机的 9 格：以机头为中心的 3×3。不检查越界——越界由 checkPlacement 负责。 */
    public static List<Cell> cellsOfPlane(Cell head) {
        List<Cell> cells = new ArrayList<>(9);
        for (int row = head.row() - 1; row <= head.row() + 1; row++) {
            for (int col = head.col() - 1; col <= head.col() + 1; col++) {
                cells.add(new Cell(row, col));
            }
        }
        return cells;
    }

    /** 机头是否能让整架飞机落在棋盘内。合法范围是 1..boardSize-2（机身要向四周各扩一格）。 */
    public static boolean isPlacementValid(Cell head, int boardSize) {
        return head.row() >= 1 && head.row() <= boardSize - 2
            && head.col() >= 1 && head.col() <= boardSize - 2;
    }

    public enum PlacementReason { COUNT, OUT_OF_BOUNDS, OVERLAP }

    public record PlacementCheck(boolean ok, PlacementReason reason) {
        public static final PlacementCheck OK = new PlacementCheck(true, null);
        static PlacementCheck fail(PlacementReason r) { return new PlacementCheck(false, r); }
    }

    /** 校验一组机头。检查顺序即优先级：count → outOfBounds → overlap。 */
    public static PlacementCheck checkPlacement(List<Cell> heads, int boardSize, int planeCount) {
        if (heads.size() != planeCount) return PlacementCheck.fail(PlacementReason.COUNT);

        for (Cell head : heads) {
            if (!isPlacementValid(head, boardSize)) return PlacementCheck.fail(PlacementReason.OUT_OF_BOUNDS);
        }

        Set<String> seen = new LinkedHashSet<>();
        for (Cell head : heads) {
            for (Cell cell : cellsOfPlane(head)) {
                if (!seen.add(cell.key())) return PlacementCheck.fail(PlacementReason.OVERLAP);
            }
        }
        return PlacementCheck.OK;
    }

    public enum ShotResult { MISS, BODY, HEAD }

    public record ShotResolution(ShotResult result, String planeId) {
        public static final ShotResolution MISS = new ShotResolution(ShotResult.MISS, null);
    }

    /**
     * 一炮打在 planes 上的结果。
     * 必须先判机头再判机身：机头本身也包含在 cellsOfPlane 的 9 格里，顺序反了会把机头误判成 body。
     */
    public static ShotResolution resolveShot(List<Plane> planes, Cell cell) {
        String target = cell.key();
        for (Plane plane : planes) {
            if (plane.head().key().equals(target)) return new ShotResolution(ShotResult.HEAD, plane.id());
        }
        for (Plane plane : planes) {
            for (Cell c : cellsOfPlane(plane.head())) {
                if (c.key().equals(target)) return new ShotResolution(ShotResult.BODY, plane.id());
            }
        }
        return ShotResolution.MISS;
    }

    /**
     * 由已命中的机身格推导可能的机头位置：H(c) = c 的 8 邻域内的合法机头（不含 c 自身）。
     * 多个命中取交集；无命中时返回全部合法位置。（spec §二「机头必然在该格的 8 邻域内」）
     */
    public static List<Cell> candidateHeads(List<Cell> bodyHits, int boardSize) {
        List<Cell> candidates = new ArrayList<>();
        for (int row = 1; row <= boardSize - 2; row++) {
            for (int col = 1; col <= boardSize - 2; col++) {
                candidates.add(new Cell(row, col));
            }
        }
        for (Cell hit : bodyHits) {
            String hitKey = hit.key();
            candidates = candidates.stream()
                .filter(h -> !h.key().equals(hitKey)
                    && cellsOfPlane(h).stream().anyMatch(c -> c.key().equals(hitKey)))
                .toList();
            if (candidates.isEmpty()) break;
        }
        return candidates;
    }

    /** 所有飞机都被击落 ⇒ 该方输。空列表视为已结束（防御性）。 */
    public static boolean isAllPlanesDestroyed(List<Plane> planes, List<String> destroyedPlaneIds) {
        return planes.stream().allMatch(p -> destroyedPlaneIds.contains(p.id()));
    }

    /** 这一格是否已经打过。 */
    public static boolean isRepeatShot(Set<String> shotKeys, Cell cell) {
        return shotKeys.contains(cell.key());
    }

    /** 棋盘上所有未打过的格子。用于超时代打。 */
    public static List<Cell> unshotCells(int boardSize, Set<String> shotKeys) {
        List<Cell> out = new ArrayList<>();
        for (int row = 0; row < boardSize; row++) {
            for (int col = 0; col < boardSize; col++) {
                if (!shotKeys.contains(row + "," + col)) out.add(new Cell(row, col));
            }
        }
        return out;
    }
}
