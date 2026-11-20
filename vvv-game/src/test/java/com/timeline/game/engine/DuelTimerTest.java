package com.timeline.game.engine;

import com.timeline.game.domain.GameTypes;
import com.timeline.game.domain.Rules;
import com.timeline.game.domain.Ruleset;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.function.DoubleSupplier;

import static org.junit.jupiter.api.Assertions.*;

/** 回合与摆放计时单测（镜像 TS apps/server/test/duel-timer.test.ts 全部预期）。 */
class DuelTimerTest {

    /** TS: const rules: RuleSet = { boardSize: 10, planeCount: 1, turnSeconds: 20, hintAllowed: true } */
    private static final Ruleset.RuleSet RULES = new Ruleset.RuleSet(10, 1, 20, true);
    /** placeSeconds(rules) = 30 + 15 × 1 = 45 秒 */
    private static final long PLACE_MS = 45_000;
    /** TS: rng: () => 0 */
    private static final DoubleSupplier ZERO = () -> 0;

    private static Rules.Cell cell(int row, int col) { return new Rules.Cell(row, col); }

    private static DuelEngine placing() {
        return new DuelEngine(new Engine.EngineOptions(RULES, List.of("a", "b"), 0, ZERO));
    }

    private static DuelEngine placing(Ruleset.RuleSet rules) {
        return new DuelEngine(new Engine.EngineOptions(rules, List.of("a", "b"), 0, ZERO));
    }

    private static DuelEngine playing() {
        return playing(RULES);
    }

    private static DuelEngine playing(Ruleset.RuleSet rules) {
        DuelEngine e = placing(rules);
        e.handle("a", new Engine.GameCommand.Place(List.of(cell(2, 2))), 0);
        e.handle("b", new Engine.GameCommand.Place(List.of(cell(7, 7))), 0);
        return e;
    }

    private static boolean hasEvent(List<Outbound> out, Class<? extends EngineEvent> cls) {
        return out.stream().anyMatch(o -> cls.isInstance(o.event()));
    }

    private static EngineEvent.GameShot firstShot(List<Outbound> out) {
        return out.stream().map(Outbound::event).filter(EngineEvent.GameShot.class::isInstance)
            .map(EngineEvent.GameShot.class::cast).findFirst().orElse(null);
    }

    @Test
    void 未到回合时长什么都不做() {
        // TS it('未到 20 秒什么都不做')
        DuelEngine r = playing();
        assertEquals(List.of(), r.tick(19999));
    }

    @Test
    void 到回合时长时代打一炮并换手() {
        // TS it('到 20 秒时代打一炮并换手')
        DuelEngine r = playing();
        String turn = r.view("a").turn();
        List<Outbound> out = r.tick(20000);
        assertTrue(hasEvent(out, EngineEvent.GameShot.class));
        assertNotEquals(turn, r.view("a").turn());
    }

    @Test
    void 回合时长取自规则十五秒() {
        // TS it('回合时长取自 rules（15 秒）')
        DuelEngine r = playing(new Ruleset.RuleSet(10, 1, 15, true));
        assertEquals(15000L, r.view("a").deadlineAt());
        assertEquals(List.of(), r.tick(14999));
        List<Outbound> out = r.tick(15000);
        EngineEvent.GameShot shot = firstShot(out);
        assertNotNull(shot);
        assertEquals("a", shot.by());
        assertEquals(30000L, r.view("a").deadlineAt());
    }

    @Test
    void 代打一定选未打过的格子() {
        // TS it('代打一定选未打过的格子')
        DuelEngine r = playing();
        String turn = r.view("a").turn();
        r.handle(turn, new Engine.GameCommand.Fire(1, 1), 100);
        // 现在对手回合，等对手超时
        List<Outbound> out = r.tick(100 + 20000);
        EngineEvent.GameShot shot = firstShot(out);
        assertNotNull(shot);
        assertNotEquals(List.of(1, 1), List.of(shot.row(), shot.col()));
    }

    @Test
    void 连续tick不会重复代打() {
        // TS it('连续 tick 不会重复代打')
        DuelEngine r = playing();
        r.tick(20000);
        assertEquals(List.of(), r.tick(20001));
    }

    @Test
    void 摆放时长到点未摆自动落子() {
        // TS it('摆放时长到点未摆自动落子')
        DuelEngine r = placing();
        assertEquals(List.of(), r.tick(PLACE_MS - 1));
        List<Outbound> out = r.tick(PLACE_MS);
        assertTrue(hasEvent(out, EngineEvent.PlaneAccepted.class));
    }

    @Test
    void 自动落子后双方都摆好则进入playing() {
        // TS it('自动落子后双方都摆好则进入 playing')
        DuelEngine r = placing();
        r.handle("a", new Engine.GameCommand.Place(List.of(cell(2, 2))), 0);
        List<Outbound> out = r.tick(PLACE_MS);
        assertEquals(GameTypes.GamePhase.PLAYING, r.phase());
        assertEquals(List.of("b"),
            out.stream().filter(o -> o.event() instanceof EngineEvent.PlaneAccepted)
                .map(Outbound::to).toList());
        assertEquals(PLACE_MS + 20000, r.view("a").deadlineAt());
    }

    @Test
    void 自动落子的位置合法() {
        // TS it('自动落子的位置合法')
        DuelEngine r = placing();
        r.tick(PLACE_MS);
        GameTypes.YouView you = r.view("a").you();
        Rules.Cell p = you.planes().get(0);
        assertTrue(p.row() >= 1);
        assertTrue(p.row() <= 8);
    }

    @Test
    void 摆放超时不判负() {
        // TS it('摆放超时不判负（spec §二）')
        DuelEngine r = placing();
        List<Outbound> out = r.tick(PLACE_MS);
        assertFalse(hasEvent(out, EngineEvent.GameOver.class));
    }

    @Test
    void 摆放deadline以开局时刻为基准而非绝对值() {
        // TS it('摆放 deadline 以开局时刻为基准，而非绝对值（真实时钟回归）')
        long T = 1_700_000_000_000L;
        DuelEngine r = new DuelEngine(new Engine.EngineOptions(RULES, List.of("a", "b"), T, ZERO));
        assertEquals(List.of(), r.tick(T + 1000));
        assertEquals(T + PLACE_MS, r.view("a").deadlineAt());
    }
}
