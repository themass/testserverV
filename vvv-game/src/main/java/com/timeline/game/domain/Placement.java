package com.timeline.game.domain;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.function.DoubleSupplier;

/**
 * 自动摆放（TS packages/shared/src/placement.ts 直译）。
 * 随机性只来自传入的 rng（[0,1) 双精度），保证同一随机源下结果确定——
 * Fisher-Yates 洗牌与 Math.floor(rng() * (i+1)) 逐步对齐 TS。
 */
public final class Placement {

    private Placement() {}

    private static final int MAX_ATTEMPTS = 200;

    /** 返回 planeCount 个互不重叠、全在棋盘内的机头。 */
    public static List<Rules.Cell> autoPlace(int boardSize, int planeCount, DoubleSupplier rng) {
        List<Rules.Cell> all = new ArrayList<>();
        for (int row = 1; row <= boardSize - 2; row++) {
            for (int col = 1; col <= boardSize - 2; col++) {
                all.add(new Rules.Cell(row, col));
            }
        }

        for (int attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
            List<Rules.Cell> order = new ArrayList<>(all);
            for (int i = order.size() - 1; i > 0; i--) {
                int j = (int) Math.floor(rng.getAsDouble() * (i + 1));
                Rules.Cell tmp = order.get(i);
                order.set(i, order.get(j));
                order.set(j, tmp);
            }
            Set<String> used = new HashSet<>();
            List<Rules.Cell> heads = new ArrayList<>();
            for (Rules.Cell head : order) {
                List<Rules.Cell> cells = Rules.cellsOfPlane(head);
                boolean overlap = false;
                for (Rules.Cell c : cells) {
                    if (used.contains(c.key())) { overlap = true; break; }
                }
                if (overlap) continue;
                for (Rules.Cell c : cells) used.add(c.key());
                heads.add(head);
                if (heads.size() == planeCount) return heads;
            }
        }

        // 保底：机头取 (1+3i, 1+3j) 的整齐网格，行优先。
        int perAxis = (boardSize - 3) / 3 + 1;
        List<Rules.Cell> heads = new ArrayList<>();
        for (int i = 0; i < perAxis && heads.size() < planeCount; i++) {
            for (int j = 0; j < perAxis && heads.size() < planeCount; j++) {
                heads.add(new Rules.Cell(1 + 3 * i, 1 + 3 * j));
            }
        }
        return heads;
    }
}
