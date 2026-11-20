package com.timeline.game.engine;

import com.timeline.game.domain.GameTypes;
import com.timeline.game.domain.Rules;
import com.timeline.game.domain.Ruleset;
import com.timeline.game.protocol.GameErrorCode;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.function.DoubleSupplier;

import static org.junit.jupiter.api.Assertions.*;

/** 断线单测（镜像 TS apps/server/test/duel-disconnect.test.ts 全部预期）。 */
class DuelDisconnectTest {

    /** TS: const rules: RuleSet = { boardSize: 10, planeCount: 1, turnSeconds: 20, hintAllowed: true } */
    private static final Ruleset.RuleSet RULES = new Ruleset.RuleSet(10, 1, 20, true);
    /** TS: rng: () => 0 */
    private static final DoubleSupplier ZERO = () -> 0;

    private static Rules.Cell cell(int row, int col) { return new Rules.Cell(row, col); }

    /** TS: const playing = () => {...} */
    private static DuelEngine playing() {
        DuelEngine r = new DuelEngine(new Engine.EngineOptions(RULES, List.of("a", "b"), 0, ZERO));
        r.handle("a", new Engine.GameCommand.Place(List.of(cell(2, 2))), 0);
        r.handle("b", new Engine.GameCommand.Place(List.of(cell(7, 7))), 0);
        return r;
    }

    private static boolean hasEvent(List<Outbound> out, Class<? extends EngineEvent> cls) {
        return out.stream().anyMatch(o -> cls.isInstance(o.event()));
    }

    private static EngineEvent.GameOver firstGameOver(List<Outbound> out) {
        return out.stream().map(Outbound::event).filter(EngineEvent.GameOver.class::isInstance)
            .map(EngineEvent.GameOver.class::cast).findFirst().orElse(null);
    }

    @Test
    void 断线进入paused并通知对手() {
        // TS it('断线进入 paused 并通知对手')
        DuelEngine r = playing();
        List<Outbound> out = r.setConnected("b", false, 1000);
        assertEquals(GameTypes.GamePhase.PAUSED, r.phase());
        assertTrue(out.contains(new Outbound("a", new EngineEvent.Presence("b", false))));
        assertFalse(r.view("a").others().get(0).connected());
    }

    @Test
    void 暂停期间不代打() {
        // TS it('暂停期间不代打（spec §二）')
        // 26000 已过回合 deadline(20000)，仍在 30 秒宽限内（1000+30000=31000）
        // ⇒ 若是普通回合超时会代打一炮，暂停时必须什么都不做
        DuelEngine r = playing();
        r.setConnected("b", false, 1000);
        assertEquals(List.of(), r.tick(26000));
    }

    @Test
    void 暂停期间对手不能开炮() {
        // TS it('暂停期间对手不能开炮')
        DuelEngine r = playing();
        String turn = r.view("a").turn();
        r.setConnected(turn.equals("a") ? "b" : "a", false, 1000);
        List<Outbound> out = r.handle(turn, new Engine.GameCommand.Fire(1, 1), 1500);
        EngineEvent.Error err = assertInstanceOf(EngineEvent.Error.class, out.get(0).event());
        assertEquals(GameErrorCode.PAUSED, err.code());
    }

    @Test
    void 重连恢复原阶段并顺延deadline() {
        // TS it('重连恢复原阶段并顺延 deadline')
        DuelEngine r = playing();
        long before = r.view("a").deadlineAt();
        r.setConnected("b", false, 1000);
        List<Outbound> out = r.setConnected("b", true, 11000); // 断了 10 秒
        assertEquals(GameTypes.GamePhase.PLAYING, r.phase());
        assertTrue(out.contains(new Outbound("a", new EngineEvent.Presence("b", true))));
        assertEquals(before + 10000, r.view("a").deadlineAt());
    }

    @Test
    void 超过30秒未回判负() {
        // TS it('超过 30 秒未回判负')
        DuelEngine r = playing();
        r.setConnected("b", false, 1000);
        List<Outbound> out = r.tick(1000 + 30000);
        assertEquals(GameTypes.GamePhase.FINISHED, r.phase());
        EngineEvent.GameOver go = firstGameOver(out);
        assertNotNull(go);
        assertEquals("a", go.result().ranking().get(0).playerId());
        assertEquals(GameTypes.GameOverReason.FORFEIT, go.result().reason());
    }

    @Test
    void 宽限期内重连不判负() {
        // TS it('宽限期内重连不判负（Review Focus #3 边界）')
        DuelEngine r = playing();
        r.setConnected("b", false, 1000);
        List<Outbound> out = r.setConnected("b", true, 30999); // 只差 1 毫秒
        assertEquals(GameTypes.GamePhase.PLAYING, r.phase());
        assertFalse(hasEvent(out, EngineEvent.GameOver.class));
    }

    @Test
    void 恰好到30秒时先tick则判负之后重连无效() {
        // TS it('恰好到 30 秒时先 tick 则判负，之后重连无效（Review Focus #3）')
        DuelEngine r = playing();
        r.setConnected("b", false, 1000);
        r.tick(31000); // 判负先生效
        assertEquals(GameTypes.GamePhase.FINISHED, r.phase());
        List<Outbound> out = r.setConnected("b", true, 31000);
        assertFalse(hasEvent(out, EngineEvent.GameOver.class));
        assertEquals(GameTypes.GamePhase.FINISHED, r.phase());
    }

    @Test
    void 摆放阶段断线也冻结() {
        // TS it('摆放阶段断线也冻结')
        DuelEngine r = new DuelEngine(new Engine.EngineOptions(RULES, List.of("a", "b"), 0, ZERO));
        r.setConnected("a", false, 0);
        assertEquals(GameTypes.GamePhase.PAUSED, r.phase());
        // 若未暂停，宽限内 tick 到摆放 deadline 附近也不能自动落子
        assertEquals(List.of(), r.tick(29000));
    }

    @Test
    void 摆放阶段重连顺延摆放deadline() {
        // TS it('摆放阶段重连顺延摆放 deadline')
        DuelEngine r = new DuelEngine(new Engine.EngineOptions(RULES, List.of("a", "b"), 0, ZERO));
        r.setConnected("a", false, 1000);
        List<Outbound> out = r.setConnected("a", true, 21000);
        assertEquals(GameTypes.GamePhase.PLACING, r.phase());
        assertEquals(45_000L + 20_000L, r.view("a").deadlineAt());
        EngineEvent.PhaseChanged pc = out.stream()
            .filter(o -> o.to().equals("b") && o.event() instanceof EngineEvent.PhaseChanged)
            .map(o -> (EngineEvent.PhaseChanged) o.event()).findFirst().orElse(null);
        assertNotNull(pc);
        assertEquals(GameTypes.GamePhase.PLACING, pc.phase());
        assertEquals(65000L, pc.deadlineAt());
        assertEquals(List.of(), r.tick(64999));
        assertTrue(hasEvent(r.tick(65000), EngineEvent.PlaneAccepted.class));
    }
}
