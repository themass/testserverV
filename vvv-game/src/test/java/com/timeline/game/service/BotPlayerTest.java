package com.timeline.game.service;

import com.timeline.game.domain.GameTypes;
import com.timeline.game.domain.Mulberry32;
import com.timeline.game.domain.Rules;
import com.timeline.game.domain.Ruleset;
import com.timeline.game.engine.Engine;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Optional;
import java.util.function.DoubleSupplier;

import static org.junit.jupiter.api.Assertions.*;

/** 电脑出手时机单测（镜像 TS apps/server/test/bot-driver.test.ts 全部预期）。 */
class BotPlayerTest {

    /** TS: const RULES: RuleSet = { boardSize: 10, planeCount: 2, turnSeconds: 20, hintAllowed: true } */
    private static final Ruleset.RuleSet RULES = new Ruleset.RuleSet(10, 2, 20, true);
    private static final String BOT = "bot_1";

    private static Rules.Cell cell(int row, int col) { return new Rules.Cell(row, col); }

    /** TS view(o)：默认 duel + playing + 轮到自己 + 已摆一架。 */
    private record Spec(GameTypes.Mode mode, GameTypes.GamePhase phase, Long deadlineAt,
                        String turn, Integer round,
                        List<Rules.Cell> planes, List<GameTypes.TargetShot> shots,
                        boolean alive, boolean submitted, Rules.Cell pendingShot) {

        static Spec of(GameTypes.Mode mode, GameTypes.GamePhase phase, Long deadlineAt,
                       String turn, Integer round) {
            return new Spec(mode, phase, deadlineAt, turn, round,
                List.of(cell(3, 3)), List.of(), true, false, null);
        }

        Spec withPlanes(List<Rules.Cell> p) { return new Spec(mode, phase, deadlineAt, turn, round, p, shots, alive, submitted, pendingShot); }
        Spec withShots(List<GameTypes.TargetShot> s) { return new Spec(mode, phase, deadlineAt, turn, round, planes, s, alive, submitted, pendingShot); }
        Spec withAlive(boolean a) { return new Spec(mode, phase, deadlineAt, turn, round, planes, shots, a, submitted, pendingShot); }
        Spec withSubmitted(boolean sub, Rules.Cell pend) { return new Spec(mode, phase, deadlineAt, turn, round, planes, shots, alive, sub, pend); }
        Spec withPhase(GameTypes.GamePhase p) { return new Spec(mode, p, deadlineAt, turn, round, planes, shots, alive, submitted, pendingShot); }
        Spec withTurn(String t) { return new Spec(mode, phase, deadlineAt, t, round, planes, shots, alive, submitted, pendingShot); }
        Spec withDeadline(Long d) { return new Spec(mode, phase, d, turn, round, planes, shots, alive, submitted, pendingShot); }

        GameTypes.GameView view() {
            return new GameTypes.GameView(mode, phase, deadlineAt, turn, round,
                new GameTypes.YouView(planes, 0, alive, shots, List.of(), submitted, pendingShot),
                List.of(new GameTypes.OtherPlayerView("h", true, true, 0, false)));
        }
    }

    /** TS: const placing = (o) => view({ phase: 'placing', turn: null, you: { planes: [] }, ...o }) */
    private static Spec placing() {
        return Spec.of(GameTypes.Mode.DUEL, GameTypes.GamePhase.PLACING, null, null, null)
            .withPlanes(List.of());
    }

    /** TS: const melee = (round, o) => view({ mode: 'melee', turn: null, round, ...o }) */
    private static Spec melee(int round) {
        return Spec.of(GameTypes.Mode.MELEE, GameTypes.GamePhase.PLAYING, null, null, round);
    }

    /** TS: const view = (o) => ... —— duel、轮到自己。 */
    private static Spec live() {
        return Spec.of(GameTypes.Mode.DUEL, GameTypes.GamePhase.PLAYING, null, BOT, null);
    }

    private static BotPlayer mk(int seed) {
        return new BotPlayer(BOT, Ruleset.PresetId.STANDARD, Mulberry32.of(seed));
    }

    private static BotPlayer mk() {
        return mk(1);
    }

    /** TS firstActionAt：在 [from, to] 内以 step 步长不断 poll，返回第一次出手的时间；没有则 null。 */
    private static Long firstActionAt(BotPlayer d, GameTypes.GameView v, long from, long to, long step) {
        for (long t = from; t <= to; t += step) {
            if (d.poll(v, RULES, t).isPresent()) return t;
        }
        return null;
    }

    private static Long firstActionAt(BotPlayer d, GameTypes.GameView v, long from, long to) {
        return firstActionAt(d, v, from, to, 50);
    }

    @Test
    void 常量() {
        // TS it('常量')
        assertEquals(1200, BotPlayer.THINK_LO_MS);
        assertEquals(3500, BotPlayer.THINK_HI_MS);
        assertEquals(1000, BotPlayer.DEADLINE_MARGIN_MS);
    }

    @Test
    void 摆放思考时间内不出手到点出摆放且合法() {
        // TS it('摆放：思考时间内不出手，到点出 placePlane 且合法')
        BotPlayer d = mk();
        GameTypes.GameView v = placing().view();
        assertTrue(d.poll(v, RULES, 10_000).isEmpty());
        assertTrue(d.poll(v, RULES, 10_000 + 1199).isEmpty());
        Engine.GameCommand.Place msg = assertInstanceOf(Engine.GameCommand.Place.class,
            d.poll(v, RULES, 10_000 + 3500).orElse(null));
        assertEquals(RULES.planeCount(), msg.planes().size());
        for (Rules.Cell h : msg.planes()) assertTrue(Rules.isPlacementValid(h, RULES.boardSize()));
        List<String> cells = msg.planes().stream()
            .flatMap(h -> Rules.cellsOfPlane(h).stream())
            .map(Rules.Cell::key).toList();
        assertEquals(cells.size(), new java.util.LinkedHashSet<>(cells).size());
    }

    @Test
    void duel非己回合返回null轮到自己后在思考区间内出火() {
        // TS it('duel：非己回合返回 null；轮到自己后在 [1200, 3500] ms 内出 fire')
        for (int seed = 1; seed <= 20; seed++) {
            BotPlayer d = mk(seed);
            GameTypes.GameView theirs = live().withTurn("h").view(); // 对手回合 → 决策键为 null
            GameTypes.GameView mine = live().view();                  // turn == BOT
            for (long t = 0; t <= 6000; t += 500) {
                assertTrue(d.poll(theirs, RULES, t).isEmpty(), "seed=" + seed + " t=" + t);
            }
            long t0 = 10_000;
            assertTrue(d.poll(mine, RULES, t0).isEmpty(), "seed=" + seed);
            Long hit = firstActionAt(d, mine, t0 + 1, t0 + 3600, 1);
            assertNotNull(hit, "seed=" + seed);
            assertTrue(hit >= t0 + 1200, "seed=" + seed + " hit=" + hit);
            assertTrue(hit <= t0 + 3500, "seed=" + seed + " hit=" + hit);
        }
    }

    @Test
    void duel出的fire在棋盘内() {
        // TS it('duel：出的 fire 在棋盘内')
        BotPlayer d = mk();
        GameTypes.GameView v = live().view();
        d.poll(v, RULES, 0);
        Engine.GameCommand.Fire msg = assertInstanceOf(Engine.GameCommand.Fire.class,
            d.poll(v, RULES, 3500).orElse(null));
        assertTrue(msg.row() >= 0 && msg.row() < RULES.boardSize());
        assertTrue(msg.col() >= 0 && msg.col() < RULES.boardSize());
    }

    @Test
    void duel暂停期间不出手恢复后重新计时() {
        // TS it('duel：paused 期间不出手；恢复后重新计时')
        BotPlayer d = mk();
        GameTypes.GameView liveV = live().view();
        assertTrue(d.poll(liveV, RULES, 0).isEmpty()); // 计划 actAt ∈ [1200, 3500]
        GameTypes.GameView paused = live().withPhase(GameTypes.GamePhase.PAUSED).view();
        for (long t = 100; t <= 20_000; t += 500) {
            assertTrue(d.poll(paused, RULES, t).isEmpty(), "t=" + t);
        }
        // 恢复：立即 poll 不出手（重新计时，至少 1200 ms 之后）
        assertTrue(d.poll(liveV, RULES, 20_000).isEmpty());
        assertTrue(d.poll(liveV, RULES, 20_000 + 1199).isEmpty());
        assertInstanceOf(Engine.GameCommand.Fire.class, d.poll(liveV, RULES, 20_000 + 3500).orElse(null));
    }

    @Test
    void melee已提交后本轮不再出手新一轮再出手一次() {
        // TS it('melee：已提交（you.submitted）后本轮不再出手；新一轮再出手一次')
        BotPlayer d = mk();
        GameTypes.GameView r1 = melee(1).view();
        assertTrue(d.poll(r1, RULES, 0).isEmpty());
        assertInstanceOf(Engine.GameCommand.Fire.class, d.poll(r1, RULES, 3500).orElse(null));
        GameTypes.GameView r1done = melee(1).withSubmitted(true, cell(1, 1)).view();
        for (long t = 3600; t <= 30_000; t += 700) {
            assertTrue(d.poll(r1done, RULES, t).isEmpty(), "t=" + t);
        }
        GameTypes.GameView r2 = melee(2).view();
        assertTrue(d.poll(r2, RULES, 40_000).isEmpty());
        assertInstanceOf(Engine.GameCommand.Fire.class, d.poll(r2, RULES, 43_500).orElse(null));
        assertTrue(d.poll(r2, RULES, 50_000).isEmpty());
    }

    @Test
    void melee出局后永不出手() {
        // TS it('melee：出局（you.alive=false）后永不出手')
        BotPlayer d = mk();
        GameTypes.GameView dead = melee(3).withAlive(false).view();
        for (long t = 0; t <= 60_000; t += 500) {
            assertTrue(d.poll(dead, RULES, t).isEmpty(), "t=" + t);
        }
    }

    @Test
    void finished后永不出手() {
        // TS it('finished 后永不出手')
        BotPlayer d = mk();
        d.poll(live().view(), RULES, 0);
        GameTypes.GameView fin = live().withPhase(GameTypes.GamePhase.FINISHED).withTurn(null).view();
        for (long t = 0; t <= 60_000; t += 500) {
            assertTrue(d.poll(fin, RULES, t).isEmpty(), "t=" + t);
        }
        GameTypes.GameView finPlacing = placing().withPhase(GameTypes.GamePhase.FINISHED).view();
        for (long t = 0; t <= 60_000; t += 500) {
            assertTrue(d.poll(finPlacing, RULES, t).isEmpty(), "t=" + t);
        }
    }

    @Test
    void 截止保护deadline只剩一千五百毫秒时最晚在deadline前一千毫秒出手() {
        // TS it('截止保护：deadline 只剩 1500 ms 时，最晚在 deadline − 1000 出手')
        for (int seed = 1; seed <= 30; seed++) {
            BotPlayer d = mk(seed);
            long now = 100_000;
            GameTypes.GameView v = live().withDeadline(now + 1500).view();
            d.poll(v, RULES, now);
            Long hit = firstActionAt(d, v, now + 1, now + 1500, 1);
            assertNotNull(hit, "seed=" + seed);
            assertTrue(hit <= now + 1500 - BotPlayer.DEADLINE_MARGIN_MS, "seed=" + seed + " hit=" + hit);
        }
    }

    @Test
    void 截止保护deadline已不足一千毫秒时立即出手() {
        // TS it('截止保护：deadline 已不足 1000 ms 时立即出手（不早于 now）')
        BotPlayer d = mk();
        GameTypes.GameView v = live().withDeadline(5_500L).view();
        assertInstanceOf(Engine.GameCommand.Fire.class, d.poll(v, RULES, 5_000).orElse(null));
    }

    @Test
    void 同一键只出手一次() {
        // TS it('同一键只出手一次（连续 poll 不重复返回动作）')
        BotPlayer d = mk();
        GameTypes.GameView v = live().view();
        d.poll(v, RULES, 0);
        assertInstanceOf(Engine.GameCommand.Fire.class, d.poll(v, RULES, 3500).orElse(null));
        for (long t = 3501; t <= 30_000; t += 250) {
            assertTrue(d.poll(v, RULES, t).isEmpty(), "t=" + t);
        }
    }

    @Test
    void duel自己再次轮到是新的决策点() {
        // TS it('duel：自己再次轮到（shots 增加）是新的决策点')
        BotPlayer d = mk();
        GameTypes.GameView v1 = live().view();
        d.poll(v1, RULES, 0);
        assertInstanceOf(Engine.GameCommand.Fire.class, d.poll(v1, RULES, 3500).orElse(null));
        GameTypes.GameView v2 = live().withShots(
            List.of(new GameTypes.TargetShot("h", 0, 0, Rules.ShotResult.MISS, "p0"))).view();
        assertTrue(d.poll(v2, RULES, 10_000).isEmpty());
        assertInstanceOf(Engine.GameCommand.Fire.class, d.poll(v2, RULES, 13_500).orElse(null));
    }

    @Test
    void 摆放已有飞机不再摆放() {
        // TS it('摆放：已有飞机（you.planes 非空）不再摆放')
        BotPlayer d = mk();
        GameTypes.GameView v = placing().withPlanes(List.of(cell(3, 3), cell(6, 6))).view();
        for (long t = 0; t <= 10_000; t += 500) {
            assertTrue(d.poll(v, RULES, t).isEmpty(), "t=" + t);
        }
    }

    @Test
    void 摆放同一键只出一次即使引擎拒绝() {
        // TS it('摆放：同一键只出一次，即使引擎拒绝（planes 仍为空）')
        BotPlayer d = mk();
        GameTypes.GameView v = placing().view();
        d.poll(v, RULES, 0);
        assertInstanceOf(Engine.GameCommand.Place.class, d.poll(v, RULES, 3500).orElse(null));
        for (long t = 3501; t <= 30_000; t += 500) {
            assertTrue(d.poll(v, RULES, t).isEmpty(), "t=" + t);
        }
    }

    @Test
    void 同seed同视图输出确定() {
        // TS it('同 seed 同视图输出确定')
        assertEquals(run(7), run(7));
    }

    private static Optional<Engine.GameCommand> run(int seed) {
        BotPlayer d = mk(seed);
        GameTypes.GameView v = live().view();
        d.poll(v, RULES, 0);
        return d.poll(v, RULES, 3500);
    }

    @Test
    void playerId与难度暴露且思考时长钳制边界精确() {
        // Java 侧补充：GameBot 契约面 + scheduleAt 的精确毫秒钳制（TS 里内联在 driver.ts，只能间接测）
        BotPlayer d = new BotPlayer(BOT, Ruleset.PresetId.EXPERT, () -> 0);
        assertEquals(BOT, d.playerId());
        assertEquals(Ruleset.PresetId.EXPERT, d.difficulty());

        // rng=0 → actAt = now + 1200 整；now+1199 不动，now+1200 出手
        GameTypes.GameView v = live().view();
        assertTrue(d.poll(v, RULES, 0).isEmpty());
        assertTrue(d.poll(v, RULES, 1199).isEmpty());
        assertInstanceOf(Engine.GameCommand.Fire.class, d.poll(v, RULES, 1200).orElse(null));

        // 钳制精确值：now=1000、deadline=1500 → actAt = max(min(1000+1200, 1500−1000), 1000) = 1000，
        // 即 deadline 不足 1000ms 时同刻立即出手（不早于 now）
        BotPlayer e = new BotPlayer(BOT, Ruleset.PresetId.EXPERT, () -> 0);
        assertInstanceOf(Engine.GameCommand.Fire.class,
            e.poll(live().withDeadline(1_500L).view(), RULES, 1_000).orElse(null));

        // 钳制精确值：now=0、deadline=5000 → actAt = min(0+1200, 4000) = 1200
        BotPlayer g = new BotPlayer(BOT, Ruleset.PresetId.EXPERT, () -> 0);
        GameTypes.GameView dl = live().withDeadline(5_000L).view();
        assertTrue(g.poll(dl, RULES, 0).isEmpty());
        assertTrue(g.poll(dl, RULES, 1199).isEmpty());
        assertInstanceOf(Engine.GameCommand.Fire.class, g.poll(dl, RULES, 1200).orElse(null));

        // rng 逼近 1 → 上界逼近 now + 3500 但取不到，故 now+3500 必出手
        BotPlayer f = new BotPlayer(BOT, Ruleset.PresetId.EXPERT, () -> 0.999999999);
        GameTypes.GameView wide = live().view();
        assertTrue(f.poll(wide, RULES, 0).isEmpty());
        assertInstanceOf(Engine.GameCommand.Fire.class, f.poll(wide, RULES, 3500).orElse(null));
    }
}
