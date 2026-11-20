package com.timeline.game.engine;

import com.timeline.game.domain.GameTypes;
import com.timeline.game.domain.Rules;
import com.timeline.game.domain.Ruleset;
import com.timeline.game.protocol.GameErrorCode;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.function.DoubleSupplier;

import static org.junit.jupiter.api.Assertions.*;

/** 开炮单测（镜像 TS apps/server/test/duel-fire.test.ts 全部预期）。 */
class DuelFireTest {

    /** TS: const rules: RuleSet = { boardSize: 10, planeCount: 1, turnSeconds: 20, hintAllowed: true } */
    private static final Ruleset.RuleSet RULES = new Ruleset.RuleSet(10, 1, 20, true);
    /** TS: rng: () => 0 → 先手是 players[0] 即 'a' */
    private static final DoubleSupplier ZERO = () -> 0;

    private static Rules.Cell cell(int row, int col) { return new Rules.Cell(row, col); }

    /** TS: const started = () => {...} —— 双方摆好进入 playing。 */
    private static DuelEngine started() {
        return started(RULES, List.of(cell(2, 2)), List.of(cell(7, 7)));
    }

    private static DuelEngine started(Ruleset.RuleSet rules, List<Rules.Cell> planesA, List<Rules.Cell> planesB) {
        DuelEngine r = new DuelEngine(new Engine.EngineOptions(rules, List.of("a", "b"), 0, ZERO));
        r.handle("a", new Engine.GameCommand.Place(planesA), 0);
        r.handle("b", new Engine.GameCommand.Place(planesB), 0);
        return r;
    }

    /** TS: const firstTurn = (r) => r.view('a').turn! */
    private static String firstTurn(DuelEngine r) { return r.view("a").turn(); }

    private static boolean hasEvent(List<Outbound> out, Class<? extends EngineEvent> cls) {
        return out.stream().anyMatch(o -> cls.isInstance(o.event()));
    }

    private static EngineEvent.GameShot firstShot(List<Outbound> out) {
        return out.stream().map(Outbound::event).filter(EngineEvent.GameShot.class::isInstance)
            .map(EngineEvent.GameShot.class::cast).findFirst().orElse(null);
    }

    private static EngineEvent.GameOver firstGameOver(List<Outbound> out) {
        return out.stream().map(Outbound::event).filter(EngineEvent.GameOver.class::isInstance)
            .map(EngineEvent.GameOver.class::cast).findFirst().orElse(null);
    }

    private static EngineEvent.GameOver gameOverTo(List<Outbound> out, String to) {
        return out.stream().filter(o -> o.to().equals(to))
            .map(Outbound::event).filter(EngineEvent.GameOver.class::isInstance)
            .map(EngineEvent.GameOver.class::cast).findFirst().orElse(null);
    }

    @Test
    void 命中机头立即结束() {
        // TS it('命中机头立即结束')
        DuelEngine r = started();
        String turn = firstTurn(r);
        String target = turn.equals("a") ? "b" : "a";
        Rules.Cell head = target.equals("b") ? cell(7, 7) : cell(2, 2);
        List<Outbound> out = r.handle(turn, new Engine.GameCommand.Fire(head.row(), head.col()), 100);
        assertEquals(GameTypes.GamePhase.FINISHED, r.phase());
        assertTrue(hasEvent(out, EngineEvent.GameOver.class));
        EngineEvent.GameOver go = firstGameOver(out);
        assertEquals(turn, go.result().ranking().get(0).playerId());
        assertEquals(GameTypes.GameOverReason.HEAD, go.result().reason());
        assertEquals(go.result(), r.result());
    }

    @Test
    void 命中机身不结束并换手() {
        // TS it('命中机身不结束并换手')
        DuelEngine r = started();
        String turn = firstTurn(r);
        String target = turn.equals("a") ? "b" : "a";
        Rules.Cell head = target.equals("b") ? cell(7, 7) : cell(2, 2);
        List<Outbound> out = r.handle(turn, new Engine.GameCommand.Fire(head.row() - 1, head.col() - 1), 100);
        assertEquals(GameTypes.GamePhase.PLAYING, r.phase());
        assertNotEquals(turn, r.view("a").turn());
        EngineEvent.GameShot shot = firstShot(out);
        assertNotNull(shot);
        assertEquals(Rules.ShotResult.BODY, shot.result());
        assertEquals("p0", shot.planeId());
    }

    @Test
    void 未命中换手() {
        // TS it('未命中换手')
        DuelEngine r = started();
        String turn = firstTurn(r);
        List<Outbound> out = r.handle(turn, new Engine.GameCommand.Fire(1, 1), 100);
        EngineEvent.GameShot shot = firstShot(out);
        assertNotNull(shot);
        assertEquals(Rules.ShotResult.MISS, shot.result());
    }

    @Test
    void 非本方回合开炮被拒且不改变状态() {
        // TS it('非本方回合开炮被拒且不改变状态（Review Focus #2）')
        DuelEngine r = started();
        String turn = firstTurn(r);
        String waiting = turn.equals("a") ? "b" : "a";
        String before = r.view("a").toString();
        List<Outbound> out = r.handle(waiting, new Engine.GameCommand.Fire(1, 1), 100);
        assertEquals(1, out.size());
        assertEquals(waiting, out.get(0).to());
        EngineEvent.Error err = assertInstanceOf(EngineEvent.Error.class, out.get(0).event());
        assertEquals(GameErrorCode.NOT_YOUR_TURN, err.code());
        assertEquals(before, r.view("a").toString());
    }

    @Test
    void 重复打同一格被拒且不消耗回合() {
        // TS it('重复打同一格被拒且不消耗回合（Review Focus #1）')
        DuelEngine r = started();
        String turn = firstTurn(r);
        r.handle(turn, new Engine.GameCommand.Fire(1, 1), 100);
        String back = r.view("a").turn();
        r.handle(back, new Engine.GameCommand.Fire(9, 9), 100);
        String again = r.view("a").turn();
        List<Outbound> out = r.handle(again, new Engine.GameCommand.Fire(1, 1), 100);
        EngineEvent.Error err = assertInstanceOf(EngineEvent.Error.class, out.get(0).event());
        assertEquals(GameErrorCode.REPEAT_SHOT, err.code());
        assertEquals(again, r.view("a").turn());
    }

    @Test
    void 摆放阶段不能开炮() {
        // TS it('摆放阶段不能开炮（Review Focus #2）')
        DuelEngine r = new DuelEngine(new Engine.EngineOptions(RULES, List.of("a", "b"), 0, ZERO));
        List<Outbound> out = r.handle("a", new Engine.GameCommand.Fire(1, 1), 0);
        EngineEvent.Error err = assertInstanceOf(EngineEvent.Error.class, out.get(0).event());
        assertEquals(GameErrorCode.WRONG_PHASE, err.code());
        assertEquals(GameTypes.GamePhase.PLACING, r.phase());
    }

    @Test
    void 越界坐标被拒() {
        // TS it('越界坐标被拒')
        DuelEngine r = started();
        String turn = firstTurn(r);
        List<Outbound> out = r.handle(turn, new Engine.GameCommand.Fire(10, 1), 100);
        EngineEvent.Error err = assertInstanceOf(EngineEvent.Error.class, out.get(0).event());
        assertEquals(GameErrorCode.OUT_OF_RANGE, err.code());
    }

    @Test
    void 两炮连击的竞态第二次被拒() {
        // TS it('两炮连击的竞态：第二次被拒（Review Focus #1）')
        DuelEngine r = started();
        String turn = firstTurn(r);
        List<Outbound> out1 = r.handle(turn, new Engine.GameCommand.Fire(1, 1), 100);
        List<Outbound> out2 = r.handle(turn, new Engine.GameCommand.Fire(1, 2), 100); // 同一发送方，已换手
        assertTrue(hasEvent(out1, EngineEvent.GameShot.class));
        EngineEvent.Error err = assertInstanceOf(EngineEvent.Error.class, out2.get(0).event());
        assertEquals(GameErrorCode.NOT_YOUR_TURN, err.code());
    }

    @Test
    void 多架飞机击落一架不结束全部击落才结束且reason为allPlanes() {
        // TS it('多架飞机：击落一架不结束，全部击落才结束且 reason=allPlanes')
        Ruleset.RuleSet r2 = new Ruleset.RuleSet(10, 2, 20, true);
        DuelEngine r = new DuelEngine(new Engine.EngineOptions(r2, List.of("a", "b"), 0, ZERO));
        r.handle("a", new Engine.GameCommand.Place(List.of(cell(2, 2), cell(2, 7))), 0);
        r.handle("b", new Engine.GameCommand.Place(List.of(cell(7, 2), cell(7, 7))), 0);
        List<Outbound> out1 = r.handle("a", new Engine.GameCommand.Fire(7, 2), 10);
        assertEquals(
            new Outbound("a", new EngineEvent.PlaneDestroyed("b", "p0")),
            out1.stream().filter(o -> o.to().equals("a") && o.event() instanceof EngineEvent.PlaneDestroyed)
                .findFirst().orElse(null));
        assertFalse(hasEvent(out1, EngineEvent.GameOver.class));
        assertEquals(GameTypes.GamePhase.PLAYING, r.phase());
        assertEquals(1, r.view("a").others().get(0).planesDestroyed());
        assertEquals(1, r.view("b").you().planesDestroyed());
        r.handle("b", new Engine.GameCommand.Fire(0, 0), 20);
        List<Outbound> out2 = r.handle("a", new Engine.GameCommand.Fire(7, 7), 30);
        assertEquals(GameTypes.GamePhase.FINISHED, r.phase());
        EngineEvent.GameOver go = gameOverTo(out2, "b");
        assertNotNull(go);
        assertEquals(GameTypes.GameOverReason.ALL_PLANES, go.result().reason());
        assertEquals("a", go.result().ranking().get(0).playerId());
    }

    @Test
    void gameOver排名胜者rank1负者rank2且hits为累计命中格数() {
        // TS it('gameOver.ranking：胜者 rank 1，负者 rank 2，hits 为累计命中格数')
        DuelEngine r = started();
        r.handle("a", new Engine.GameCommand.Fire(6, 6), 10); // a 打 b 机身
        r.handle("b", new Engine.GameCommand.Fire(1, 1), 20); // b 打 a 机身
        r.handle("a", new Engine.GameCommand.Fire(0, 0), 30); // miss
        r.handle("b", new Engine.GameCommand.Fire(9, 9), 40); // miss
        List<Outbound> out = r.handle("a", new Engine.GameCommand.Fire(7, 7), 50); // a 打 b 机头
        EngineEvent.GameOver go = gameOverTo(out, "a");
        assertNotNull(go);
        assertEquals(new GameTypes.GameResult(GameTypes.GameOverReason.HEAD, List.of(
            new GameTypes.RankEntry("a", 1, null, 2),
            new GameTypes.RankEntry("b", 2, null, 1))), go.result());
    }
}
