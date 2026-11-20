package com.timeline.game.service;

import com.timeline.game.domain.GameTypes;
import com.timeline.game.domain.Rules;
import com.timeline.game.domain.Ruleset;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.DoubleSupplier;

/**
 * 电脑的决策（TS apps/server/src/bot/brain.ts 逐行直译，spec §5）。
 * 纯函数：只读传入的 GameView（engine.view(botId)），不碰任何其它状态。
 *
 * <p><b>确定性红线</b>：{@link #chooseShot} 内 rng 的调用次序固定为「误着骰 →（失误时）均匀挑
 * → 并列挑」，且候选格集合的遍历顺序与 TS 的 Map 插入序（行优先）严格一致——
 * 种子化测试要与 TS 期望逐格对上，靠的就是这两条，改动任何一处都会让对拍失效。
 * 浮点累加顺序同样对齐 TS（同样的遍历次序、同样的 {@code weight/heads.length} 与
 * {@code PART_WEIGHT * w}），因此分数值逐位相同。
 */
public final class BotBrain {

    private BotBrain() {}

    /** 难度误着率（TS BOT_MISTAKE_RATE；BotDifficulty 即 PresetId，spec §0）。 */
    public static final Map<Ruleset.PresetId, Double> BOT_MISTAKE_RATE = Map.of(
        Ruleset.PresetId.BEGINNER, 0.4,
        Ruleset.PresetId.STANDARD, 0.25,
        Ruleset.PresetId.ADVANCED, 0.1,
        Ruleset.PresetId.EXPERT, 0.0);

    /** 「这一格能命中某架飞机」相对「这一格是机头」的权重。 */
    public static final double PART_WEIGHT = 0.3;

    /** 同分判定容差（TS TIE_EPS）。 */
    static final double TIE_EPS = 1e-9;

    /** 由炮火推理出的对手棋盘模型（TS OpponentModel）。 */
    public record OpponentModel(List<Rules.Cell> feasible, List<ActivePlane> active, int unlocated) {}

    /** 有机身命中但未击落的飞机，及其候选机头。 */
    public record ActivePlane(String planeId, List<Rules.Cell> candidates) {}

    /** 稳定的格坐标键（TS cellKey）。 */
    private static String key(int row, int col) {
        return row + "," + col;
    }

    /**
     * 只用电脑打在某一对手身上的炮推理该对手的飞机位置。
     * 分组只看 body / head 的 planeId；miss 的 planeId 恒为 'p0'，不能用来分组。
     */
    public static OpponentModel opponentModel(
            List<GameTypes.TargetShot> shotsOnTarget, int planesDestroyed, Ruleset.RuleSet rules) {
        Set<String> shot = new HashSet<>();
        Set<String> missed = new HashSet<>();
        Set<String> destroyedIds = new HashSet<>();
        // 插入序 = 炮序：active 列表顺序与浮点累加顺序都依赖它，不得换成无序 Map
        Map<String, List<Rules.Cell>> bodyByPlane = new LinkedHashMap<>();

        for (GameTypes.TargetShot s : shotsOnTarget) {
            String k = key(s.row(), s.col());
            shot.add(k);
            switch (s.result()) {
                case MISS -> missed.add(k);
                case HEAD -> {
                    destroyedIds.add(s.planeId());
                    // 被击落飞机的 9 格：已知格
                    for (Rules.Cell c : Rules.cellsOfPlane(new Rules.Cell(s.row(), s.col()))) {
                        missed.add(c.key());
                    }
                }
                case BODY -> bodyByPlane
                    .computeIfAbsent(s.planeId(), id -> new ArrayList<>())
                    .add(new Rules.Cell(s.row(), s.col()));
            }
        }
        // known：未命中格 + 已击落飞机的 9 格。已击落飞机的机身命中不再作活跃线索。
        Set<String> known = missed;
        for (String id : destroyedIds) bodyByPlane.remove(id);

        List<Rules.Cell> feasible = new ArrayList<>();
        Set<String> feasibleKeys = new HashSet<>();
        int n = rules.boardSize();
        for (int row = 1; row <= n - 2; row++) {
            for (int col = 1; col <= n - 2; col++) {
                Rules.Cell h = new Rules.Cell(row, col);
                if (!Rules.isPlacementValid(h, n)) continue;
                if (shot.contains(h.key())) continue;
                boolean touchesKnown = false;
                for (Rules.Cell c : Rules.cellsOfPlane(h)) {
                    if (known.contains(c.key())) { touchesKnown = true; break; }
                }
                if (touchesKnown) continue;
                feasible.add(h);
                feasibleKeys.add(h.key());
            }
        }

        List<ActivePlane> active = new ArrayList<>();
        int activeCount = 0;
        for (Map.Entry<String, List<Rules.Cell>> e : bodyByPlane.entrySet()) {
            activeCount++;
            Set<String> others = new LinkedHashSet<>();
            for (Map.Entry<String, List<Rules.Cell>> other : bodyByPlane.entrySet()) {
                if (!other.getKey().equals(e.getKey())) {
                    for (Rules.Cell c : other.getValue()) others.add(c.key());
                }
            }
            List<Rules.Cell> candidates = new ArrayList<>();
            for (Rules.Cell h : Rules.candidateHeads(e.getValue(), n)) {
                if (!feasibleKeys.contains(h.key())) continue;
                boolean touchesOther = false;
                for (Rules.Cell c : Rules.cellsOfPlane(h)) {
                    if (others.contains(c.key())) { touchesOther = true; break; }
                }
                if (!touchesOther) candidates.add(h);
            }
            if (!candidates.isEmpty()) active.add(new ActivePlane(e.getKey(), List.copyOf(candidates)));
            // 候选为空（理论上不会发生）→ 按未定位处理，由下面的 unlocated 计入
        }

        int unlocated = Math.max(0, rules.planeCount() - planesDestroyed - activeCount)
            + (activeCount - active.size());
        return new OpponentModel(List.copyOf(feasible), List.copyOf(active), unlocated);
    }

    /** 对每个未打过的格子打分（键为 cellKey，插入序为行优先）。 */
    public static Map<String, Double> scoreCells(GameTypes.GameView view, Ruleset.RuleSet rules) {
        int n = rules.boardSize();
        Set<String> shotAny = new HashSet<>();
        for (GameTypes.TargetShot s : view.you().shots()) shotAny.add(key(s.row(), s.col()));

        Map<String, Double> scores = new LinkedHashMap<>();
        for (int row = 0; row < n; row++) {
            for (int col = 0; col < n; col++) {
                String k = key(row, col);
                if (!shotAny.contains(k)) scores.put(k, 0.0);
            }
        }

        for (GameTypes.OtherPlayerView o : view.others()) {
            if (!o.alive()) continue;
            List<GameTypes.TargetShot> shotsOnTarget = view.you().shots().stream()
                .filter(s -> s.targetId().equals(o.playerId()))
                .toList();
            OpponentModel model = opponentModel(shotsOnTarget, o.planesDestroyed(), rules);
            if (model.feasible().isEmpty()) continue;
            for (ActivePlane a : model.active()) spread(scores, a.candidates(), 1);
            if (model.unlocated() > 0) spread(scores, model.feasible(), model.unlocated());
        }
        return scores;
    }

    private static void add(Map<String, Double> scores, Rules.Cell c, double v) {
        String k = c.key();
        Double cur = scores.get(k);
        if (cur != null) scores.put(k, cur + v);
    }

    private static void spread(Map<String, Double> scores, List<Rules.Cell> heads, double weight) {
        double w = weight / heads.size();
        for (Rules.Cell h : heads) {
            add(scores, h, w);
            for (Rules.Cell c : Rules.cellsOfPlane(h)) add(scores, c, PART_WEIGHT * w);
        }
    }

    /**
     * 选一格开炮；没有可打的格子时返回 null。
     * rng 的使用顺序固定：先抽一次判定是否失误；失误则再抽一次从所有未打格子里均匀选；
     * 否则取最高分，同分再抽一次均匀选。
     */
    public static Rules.Cell chooseShot(GameTypes.GameView view, Ruleset.RuleSet rules,
                                        Ruleset.PresetId difficulty, DoubleSupplier rng) {
        boolean mistake = rng.getAsDouble() < BOT_MISTAKE_RATE.get(difficulty);
        Map<String, Double> scores = scoreCells(view, rules);
        if (scores.isEmpty()) return null;

        List<String> all = new ArrayList<>(scores.keySet()); // 行优先
        if (mistake) return pickFrom(all, rng);

        double bestValue = Double.NEGATIVE_INFINITY;
        for (double v : scores.values()) if (v > bestValue) bestValue = v;
        final double best = bestValue;
        List<String> top = all.stream()
            .filter(k -> scores.get(k) >= best - TIE_EPS)
            .toList();
        return pickFrom(top, rng);
    }

    private static Rules.Cell pickFrom(List<String> keys, DoubleSupplier rng) {
        int idx = (int) Math.min(keys.size() - 1, Math.floor(rng.getAsDouble() * keys.size()));
        String k = keys.get(idx);
        int comma = k.indexOf(',');
        return new Rules.Cell(
            Integer.parseInt(k.substring(0, comma)),
            Integer.parseInt(k.substring(comma + 1)));
    }
}
