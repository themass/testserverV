package com.timeline.game.service;

import com.timeline.game.domain.GameTypes;
import com.timeline.game.domain.Mulberry32;
import com.timeline.game.domain.Placement;
import com.timeline.game.domain.Rules;
import com.timeline.game.domain.Ruleset;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.DoubleSupplier;

import static org.junit.jupiter.api.Assertions.*;

/** 电脑决策单测（镜像 TS apps/server/test/bot-brain.test.ts 全部预期）。 */
class BotBrainTest {

    /** TS: const R10: RuleSet = { boardSize: 10, planeCount: 1, turnSeconds: 20, hintAllowed: true } */
    private static final Ruleset.RuleSet R10 = new Ruleset.RuleSet(10, 1, 20, true);

    private static Rules.Cell cell(int row, int col) { return new Rules.Cell(row, col); }

    /** TS viewWith(...)：mode = others.length > 1 ? melee : duel；others 用 "id" 或 {id, alive, planesDestroyed}。 */
    private static GameTypes.GameView viewWith(Ruleset.RuleSet rules, List<GameTypes.TargetShot> shots,
                                               List<OtherSpec> others, int planesDestroyed) {
        GameTypes.Mode mode = others.size() > 1 ? GameTypes.Mode.MELEE : GameTypes.Mode.DUEL;
        List<GameTypes.OtherPlayerView> othersV = others.stream()
            .map(o -> new GameTypes.OtherPlayerView(o.id(), true, o.alive(), o.planesDestroyed(), false))
            .toList();
        return new GameTypes.GameView(mode, GameTypes.GamePhase.PLAYING, null, null, null,
            new GameTypes.YouView(List.of(), planesDestroyed, true, shots, List.of(), false, null),
            othersV);
    }

    private static GameTypes.GameView viewWith(Ruleset.RuleSet rules, List<GameTypes.TargetShot> shots,
                                               List<OtherSpec> others) {
        return viewWith(rules, shots, others, 0);
    }

    /** TS 的 OtherSpec：字符串或 {id, alive?, planesDestroyed?}。 */
    private record OtherSpec(String id, boolean alive, int planesDestroyed) {
        static OtherSpec of(String id) { return new OtherSpec(id, true, 0); }
    }

    private static GameTypes.TargetShot body(String targetId, int row, int col, String planeId) {
        return new GameTypes.TargetShot(targetId, row, col, Rules.ShotResult.BODY, planeId);
    }

    private static GameTypes.TargetShot body(String targetId, int row, int col) {
        return body(targetId, row, col, "p0");
    }

    private static GameTypes.TargetShot head(String targetId, int row, int col, String planeId) {
        return new GameTypes.TargetShot(targetId, row, col, Rules.ShotResult.HEAD, planeId);
    }

    private static GameTypes.TargetShot miss(String targetId, int row, int col) {
        return new GameTypes.TargetShot(targetId, row, col, Rules.ShotResult.MISS, "p0");
    }

    /** TS seq(values)：依次返回，耗尽后重复最后一个。 */
    private static DoubleSupplier seq(double... values) {
        int[] i = {0};
        return () -> values[Math.min(i[0]++, values.length - 1)];
    }

    /** TS: const CORNER = viewWith({ rules: R10, shots: [body('b', 0, 0)], others: ['b'] }) */
    private static GameTypes.GameView corner() {
        return viewWith(R10, List.of(body("b", 0, 0)), List.of(OtherSpec.of("b")));
    }

    // ---------------------------------------------------------------- 常量

    @Test
    void 失误率表与部位权重() {
        // TS: expect(BOT_MISTAKE_RATE).toEqual({beginner:0.4, standard:0.25, advanced:0.1, expert:0})
        assertEquals(Map.of(
            Ruleset.PresetId.BEGINNER, 0.4,
            Ruleset.PresetId.STANDARD, 0.25,
            Ruleset.PresetId.ADVANCED, 0.1,
            Ruleset.PresetId.EXPERT, 0.0), BotBrain.BOT_MISTAKE_RATE);
        assertEquals(4, BotBrain.BOT_MISTAKE_RATE.size());
        assertEquals(0.3, BotBrain.PART_WEIGHT);
    }

    // ---------------------------------------------------------------- 推理

    @Test
    void 角上一格是机身_唯一候选机头_高手必打() {
        // TS it('角上一格是机身 → 唯一候选机头 (1,1)，高手必打')
        assertEquals(cell(1, 1),
            BotBrain.chooseShot(corner(), R10, Ruleset.PresetId.EXPERT, Mulberry32.of(1)));
    }

    @Test
    void 未命中格排除候选_只留一个候选() {
        // TS it('未命中格排除候选：机身 (4,4) + 周围未命中只留一个候选 (5,5)')
        GameTypes.GameView v = viewWith(R10, List.of(
            body("b", 4, 4), miss("b", 3, 3), miss("b", 3, 4), miss("b", 3, 5),
            miss("b", 4, 3), miss("b", 5, 3)), List.of(OtherSpec.of("b")));
        BotBrain.OpponentModel m = BotBrain.opponentModel(v.you().shots(), 0, R10);
        assertEquals(1, m.active().size());
        assertEquals(List.of(cell(5, 5)), m.active().get(0).candidates());
        assertEquals(cell(5, 5),
            BotBrain.chooseShot(v, R10, Ruleset.PresetId.EXPERT, Mulberry32.of(7)));
    }

    @Test
    void miss的planeId恒为p0但不参与机身分组() {
        // TS it('miss 的 planeId 恒为 p0，但不参与机身分组')
        BotBrain.OpponentModel m = BotBrain.opponentModel(
            List.of(miss("b", 8, 8), miss("b", 7, 8)), 0, R10);
        assertEquals(0, m.active().size());
        assertEquals(1, m.unlocated());
    }

    @Test
    void 空棋盘中心格的分数高于角格() {
        // TS it('空棋盘：中心格的分数高于角格（找机身倾向中心）')
        Map<String, Double> s = BotBrain.scoreCells(
            viewWith(R10, List.of(), List.of(OtherSpec.of("b"))), R10);
        assertTrue(s.get("5,5") > s.get("0,0"), "5,5 应高于 0,0");
    }

    @Test
    void scoreCells只含未打过的格子() {
        // TS it('scoreCells 只含未打过的格子')
        Map<String, Double> s = BotBrain.scoreCells(corner(), R10);
        assertFalse(s.containsKey("0,0"));
        assertEquals(99, s.size());
        assertEquals(1 + BotBrain.PART_WEIGHT * 1, s.get("1,1"), 1e-9);
    }

    @Test
    void 混战求和_同时是两个对手候选的格子优先() {
        // TS it('混战求和：同时是 b、c 候选机头的格子优先于只是 b 的候选')
        List<GameTypes.TargetShot> shots = List.of(body("b", 0, 1), body("c", 0, 3));
        GameTypes.GameView onlyB = viewWith(R10, shots, List.of(OtherSpec.of("b")));
        GameTypes.GameView both = viewWith(R10, shots, List.of(OtherSpec.of("b"), OtherSpec.of("c")));
        Map<String, Double> sb = BotBrain.scoreCells(onlyB, R10);
        assertEquals(sb.get("1,1"), sb.get("1,2"), 1e-9); // 只看 b：打平
        Map<String, Double> s = BotBrain.scoreCells(both, R10);
        assertTrue(s.get("1,2") > s.get("1,1"), "1,2 应高于 1,1");
        assertEquals(cell(1, 2),
            BotBrain.chooseShot(both, R10, Ruleset.PresetId.EXPERT, Mulberry32.of(3)));
    }

    @Test
    void 混战只算存活对手() {
        // TS it('混战只算存活对手：已出局对手身上的线索不影响打分')
        List<GameTypes.TargetShot> shots = List.of(body("b", 0, 1), body("c", 0, 3));
        GameTypes.GameView dead = viewWith(R10, shots,
            List.of(OtherSpec.of("b"), new OtherSpec("c", false, 0)));
        GameTypes.GameView absent = viewWith(R10, shots, List.of(OtherSpec.of("b")));
        assertEquals(new ArrayList<>(BotBrain.scoreCells(dead, R10).entrySet()),
            new ArrayList<>(BotBrain.scoreCells(absent, R10).entrySet()));
    }

    @Test
    void 多机两架活跃飞机分别推理() {
        // TS it('多机：两架活跃飞机分别推理，不把两架的机身命中求交集')
        Ruleset.RuleSet rules = new Ruleset.RuleSet(12, 2, 20, false);
        GameTypes.GameView v = viewWith(rules,
            List.of(body("b", 3, 3, "p0"), body("b", 8, 8, "p1")), List.of(OtherSpec.of("b")));
        BotBrain.OpponentModel m = BotBrain.opponentModel(v.you().shots(), 0, rules);
        assertEquals(2, m.active().size());
        assertEquals(0, m.unlocated());
        Map<String, Double> s = BotBrain.scoreCells(v, rules);
        assertTrue(s.get("2,2") >= 1 / 8.0);
        assertTrue(s.get("9,9") >= 1 / 8.0);
        assertEquals(0.0, s.get("0,11"));
        Rules.Cell pick = BotBrain.chooseShot(v, rules, Ruleset.PresetId.EXPERT, Mulberry32.of(5));
        assertNotNull(pick);
        boolean near = (near(pick, 3, 3) || near(pick, 8, 8));
        assertTrue(near);
    }

    private static boolean near(Rules.Cell c, int r, int k) {
        return Math.abs(c.row() - r) <= 1 && Math.abs(c.col() - k) <= 1;
    }

    @Test
    void 未定位飞机数等于总数减已击落减活跃数() {
        // TS it('未定位飞机数 = 总数 − 已击落 − 活跃数')
        Ruleset.RuleSet rules = new Ruleset.RuleSet(12, 3, 20, false);
        BotBrain.OpponentModel m = BotBrain.opponentModel(
            List.of(body("b", 3, 3, "p1"), head("b", 8, 8, "p0")), 1, rules);
        assertEquals(List.of("p1"), m.active().stream().map(BotBrain.ActivePlane::planeId).toList());
        assertEquals(1, m.unlocated());
    }

    @Test
    void 已击落飞机的九格不再作为别的飞机的可能位置() {
        // TS it('已击落飞机的 9 格不再作为别的飞机的可能位置')
        Ruleset.RuleSet rules = new Ruleset.RuleSet(10, 2, 20, false);
        GameTypes.GameView v = viewWith(rules,
            List.of(head("b", 4, 4, "p0"), body("b", 4, 6, "p1")),
            List.of(new OtherSpec("b", true, 1)), 0);
        BotBrain.OpponentModel m = BotBrain.opponentModel(v.you().shots(), 1, rules);
        assertEquals(List.of(cell(3, 7), cell(4, 7), cell(5, 7)), m.active().get(0).candidates());
        assertEquals(0, m.unlocated());
        assertEquals(0.0, BotBrain.scoreCells(v, rules).get("4,5"));
        assertEquals(cell(4, 7), BotBrain.chooseShot(v, rules, Ruleset.PresetId.EXPERT, Mulberry32.of(9)));
    }

    @Test
    void 同分时用rng均匀选择() {
        // TS it('同分时用 rng 均匀选择')
        Ruleset.RuleSet rules = new Ruleset.RuleSet(6, 1, 20, true);
        GameTypes.GameView v = viewWith(rules, List.of(), List.of(OtherSpec.of("b")));
        // 并列最高的 4 格（行优先）：(2,2) (2,3) (3,2) (3,3)
        assertEquals(cell(2, 2), BotBrain.chooseShot(v, rules, Ruleset.PresetId.EXPERT, seq(0.5, 0)));
        assertEquals(cell(3, 2), BotBrain.chooseShot(v, rules, Ruleset.PresetId.EXPERT, seq(0.5, 0.5)));
        assertEquals(cell(3, 3), BotBrain.chooseShot(v, rules, Ruleset.PresetId.EXPERT, seq(0.5, 0.999999)));
    }

    @Test
    void 无未打过的格子返回null() {
        // TS it('无未打过的格子 → null')
        Ruleset.RuleSet rules = new Ruleset.RuleSet(6, 1, 20, true);
        List<GameTypes.TargetShot> shots = new ArrayList<>();
        for (int r = 0; r < 6; r++) for (int c = 0; c < 6; c++) shots.add(miss("b", r, c));
        assertNull(BotBrain.chooseShot(viewWith(rules, shots, List.of(OtherSpec.of("b"))),
            rules, Ruleset.PresetId.EXPERT, Mulberry32.of(1)));
    }

    // ---------------------------------------------------------------- 失误

    /** TS deviation(difficulty, n)：以种子 0..n-1 统计偏离最优格 (1,1) 的比例。 */
    private static double deviation(Ruleset.PresetId difficulty, int n) {
        int off = 0;
        for (int i = 0; i < n; i++) {
            Rules.Cell c = BotBrain.chooseShot(corner(), R10, difficulty, Mulberry32.of(i));
            assertNotNull(c);
            if (c.row() != 1 || c.col() != 1) off++;
        }
        return (double) off / n;
    }

    private static double deviation(Ruleset.PresetId difficulty) {
        return deviation(difficulty, 2000);
    }

    @Test
    void 入门在两千次决策中偏离最优的比例在区间内() {
        // TS it('入门在 2000 次决策中偏离最优的比例 ∈ [0.33, 0.47]') —— 期望 = 0.4 × (1 − 1/99) ≈ 0.396
        double r = deviation(Ruleset.PresetId.BEGINNER);
        assertTrue(r >= 0.33 && r <= 0.47, "beginner 偏离率 = " + r);
    }

    @Test
    void 标准与进阶的偏离率在失误率正负五个百分点内() {
        // TS it.each([['standard', 0.25], ['advanced', 0.1]])
        for (Object[] c : new Object[][]{{Ruleset.PresetId.STANDARD, 0.25}, {Ruleset.PresetId.ADVANCED, 0.1}}) {
            Ruleset.PresetId d = (Ruleset.PresetId) c[0];
            double rate = (double) c[1];
            double expected = rate * (98 / 99.0);
            double actual = deviation(d);
            assertTrue(Math.abs(actual - expected) <= 0.05, d + " 偏离率 = " + actual + "，期望 " + expected);
        }
    }

    @Test
    void 高手从不偏离任何种子() {
        // TS it('高手从不偏离（任何种子）')
        assertEquals(0.0, deviation(Ruleset.PresetId.EXPERT, 1000));
    }

    @Test
    void 失误时只用到第一次rng判定() {
        // TS it('失误时只用到第一次 rng 判定：rng 恒为 0 → 入门必失误并选第一个未打格')
        assertEquals(cell(0, 1),
            BotBrain.chooseShot(corner(), R10, Ruleset.PresetId.BEGINNER, () -> 0));
    }

    @Test
    void 确定性同一种子同一结果() {
        // TS it('确定性：同一种子同一结果')
        for (int i = 0; i < 50; i++) {
            assertEquals(BotBrain.chooseShot(corner(), R10, Ruleset.PresetId.BEGINNER, Mulberry32.of(i)),
                BotBrain.chooseShot(corner(), R10, Ruleset.PresetId.BEGINNER, Mulberry32.of(i)));
        }
    }

    // ---------------------------------------------------------------- 合法性与性能

    /** TS randomShots(rules, target, n, rng)。 */
    private static List<GameTypes.TargetShot> randomShots(Ruleset.RuleSet rules, String target,
                                                          int n, DoubleSupplier rng) {
        List<Rules.Plane> planes = new ArrayList<>();
        List<Rules.Cell> heads = Placement.autoPlace(rules.boardSize(), rules.planeCount(), rng);
        for (int i = 0; i < heads.size(); i++) planes.add(new Rules.Plane("p" + i, heads.get(i)));
        Set<String> seen = new LinkedHashSet<>();
        List<GameTypes.TargetShot> out = new ArrayList<>();
        while (out.size() < n) {
            Rules.Cell c = cell((int) Math.floor(rng.getAsDouble() * rules.boardSize()),
                                (int) Math.floor(rng.getAsDouble() * rules.boardSize()));
            if (seen.contains(c.key())) continue;
            seen.add(c.key());
            Rules.ShotResolution r = Rules.resolveShot(planes, c);
            out.add(new GameTypes.TargetShot(target, c.row(), c.col(), r.result(),
                r.result() == Rules.ShotResult.MISS ? "p0" : r.planeId()));
        }
        return out;
    }

    @Test
    void 从不选已打过的格子总在棋盘内() {
        // TS it('从不选已打过的格子、总在棋盘内（随机 200 个局面）')
        DoubleSupplier rng = Mulberry32.of(2024);
        Ruleset.PresetId[] diffs = {Ruleset.PresetId.BEGINNER, Ruleset.PresetId.STANDARD,
            Ruleset.PresetId.ADVANCED, Ruleset.PresetId.EXPERT};
        for (int i = 0; i < 200; i++) {
            int boardSize = 6 + (int) Math.floor(rng.getAsDouble() * 11);
            int planeCount = 1 + (int) Math.floor(
                rng.getAsDouble() * Math.min(3, Math.floor((0.3 * boardSize * boardSize) / 9)));
            Ruleset.RuleSet rules = new Ruleset.RuleSet(boardSize, planeCount, 20, true);
            int n = (int) Math.floor(rng.getAsDouble() * (boardSize * boardSize * 0.6));
            List<GameTypes.TargetShot> shots = new ArrayList<>(randomShots(rules, "b", n, rng));
            shots.addAll(randomShots(rules, "c", (int) Math.floor(n / 2.0), rng));
            Set<String> used = new LinkedHashSet<>(shots.stream().map(s -> s.row() + "," + s.col()).toList());
            GameTypes.GameView v = viewWith(rules, shots, List.of(OtherSpec.of("b"), OtherSpec.of("c")));
            Rules.Cell pick = BotBrain.chooseShot(v, rules, diffs[i % 4], rng);
            if (used.size() >= boardSize * boardSize) {
                assertNull(pick, "i=" + i);
                continue;
            }
            assertNotNull(pick, "i=" + i);
            assertFalse(used.contains(pick.row() + "," + pick.col()), "i=" + i);
            assertTrue(pick.row() >= 0 && pick.row() < boardSize, "i=" + i);
            assertTrue(pick.col() >= 0 && pick.col() < boardSize, "i=" + i);
        }
    }

    @Test
    void 性能十六格棋盘单次chooseShot小于二十毫秒() {
        // TS it('性能：16×16、6 架、3 个对手、每人 60 炮，单次 chooseShot < 20ms')
        Ruleset.RuleSet rules = new Ruleset.RuleSet(16, 6, 20, false);
        DoubleSupplier rng = Mulberry32.of(77);
        List<GameTypes.TargetShot> shots = new ArrayList<>();
        for (String t : List.of("b", "c", "d")) shots.addAll(randomShots(rules, t, 60, rng));
        GameTypes.GameView v = viewWith(rules, shots, List.of(
            OtherSpec.of("b"), OtherSpec.of("c"), OtherSpec.of("d")));
        BotBrain.chooseShot(v, rules, Ruleset.PresetId.EXPERT, Mulberry32.of(1)); // 预热
        long t0 = System.nanoTime();
        BotBrain.chooseShot(v, rules, Ruleset.PresetId.EXPERT, Mulberry32.of(1));
        long elapsedNs = System.nanoTime() - t0;
        assertTrue(elapsedNs < 20_000_000L, "chooseShot 耗时 " + elapsedNs / 1_000_000.0 + "ms");
    }
}
