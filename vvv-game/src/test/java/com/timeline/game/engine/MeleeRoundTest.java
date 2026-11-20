package com.timeline.game.engine;

import com.timeline.game.domain.GameTypes;
import com.timeline.game.domain.Rules;
import com.timeline.game.domain.Ruleset;
import com.timeline.game.protocol.GameErrorCode;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/**
 * 镜像 TS apps/server/test/melee-round.test.ts：MeleeEngine 回合。
 * 3 人：a(2,2) b(6,6) c(2,7)；10×10、1 架、20 秒。
 */
class MeleeRoundTest {

    private static final Ruleset.RuleSet RULES = new Ruleset.RuleSet(10, 1, 20, true);
    private static final Map<String, Rules.Cell> HEADS = Map.of(
        "a", new Rules.Cell(2, 2),
        "b", new Rules.Cell(6, 6),
        "c", new Rules.Cell(2, 7));
    private static final List<String> IDS = List.of("a", "b", "c");

    private static Rules.Cell head(String id) { return HEADS.get(id); }

    private static MeleeEngine newEngine() {
        return new MeleeEngine(new Engine.EngineOptions(RULES, IDS, 0, () -> 0));
    }

    /** 摆放完毕的引擎：round 1，deadline = 20_000。 */
    private static MeleeEngine started() {
        MeleeEngine e = newEngine();
        for (String id : IDS) e.handle(id, new Engine.GameCommand.Place(List.of(head(id))), 0);
        return e;
    }

    private static List<Outbound> fire(MeleeEngine e, String id, int row, int col) {
        return fire(e, id, row, col, 100);
    }

    private static List<Outbound> fire(MeleeEngine e, String id, int row, int col, long now) {
        return e.handle(id, new Engine.GameCommand.Fire(row, col), now);
    }

    /** 取发给 to 的某一类事件（TS 的 of(out, to, type)）。 */
    private static <T extends EngineEvent> List<T> of(List<Outbound> out, String to, Class<T> type) {
        List<T> res = new ArrayList<>();
        for (Outbound o : out) {
            if (o.to().equals(to) && type.isInstance(o.event())) res.add(type.cast(o.event()));
        }
        return res;
    }

    /** 断言 out 恰好是一条发给 to 的错误事件。 */
    private static void assertSingleError(List<Outbound> out, String to, GameErrorCode code) {
        assertEquals(1, out.size(), "应只有一条错误回执");
        assertEquals(to, out.get(0).to());
        assertInstanceOf(EngineEvent.Error.class, out.get(0).event());
        assertEquals(code, ((EngineEvent.Error) out.get(0).event()).code());
    }

    /** 断言事件里不含任何坐标字段（TS 的 JSON.stringify(...).not.toMatch(/"row"|"col"/)）。 */
    private static void assertNoCoords(Object obj) {
        String s = String.valueOf(obj);
        assertFalse(s.contains("row"), "不应出现坐标 row：" + s);
        assertFalse(s.contains("col"), "不应出现坐标 col：" + s);
    }

    private static void assertShot(GameTypes.TargetShot actual, String targetId, int row, int col,
                                   Rules.ShotResult result, String planeId) {
        assertEquals(targetId, actual.targetId());
        assertEquals(row, actual.row());
        assertEquals(col, actual.col());
        assertEquals(result, actual.result());
        assertEquals(planeId, actual.planeId());
    }

    private static void assertIncoming(GameTypes.IncomingShot actual, String by, int row, int col,
                                       Rules.ShotResult result, String planeId) {
        assertEquals(by, actual.by());
        assertEquals(row, actual.row());
        assertEquals(col, actual.col());
        assertEquals(result, actual.result());
        assertEquals(planeId, actual.planeId());
    }

    // ------------------------------------------------------------------ tests

    /** TS: it('摆放完成进入 round 1，广播 phaseChanged') */
    @Test
    void 摆放完成进入round1广播phaseChanged() {
        MeleeEngine e = newEngine();
        e.handle("a", new Engine.GameCommand.Place(List.of(head("a"))), 0);
        e.handle("b", new Engine.GameCommand.Place(List.of(head("b"))), 0);
        List<Outbound> out = e.handle("c", new Engine.GameCommand.Place(List.of(head("c"))), 50);

        assertEquals(GameTypes.Mode.MELEE, e.mode());
        assertEquals(GameTypes.GamePhase.PLAYING, e.phase());
        for (String id : IDS) {
            assertEquals(List.of(new EngineEvent.PhaseChanged(GameTypes.GamePhase.PLAYING, 20_050L, null, 1)),
                of(out, id, EngineEvent.PhaseChanged.class));
        }
    }

    /** TS: it('提交只广播 submitted，不含坐标') */
    @Test
    void 提交只广播submitted不含坐标() {
        MeleeEngine e = started();
        List<Outbound> out = fire(e, "a", 9, 9);
        assertEquals(3, out.size());
        List<String> tos = out.stream().map(Outbound::to).sorted().toList();
        assertEquals(List.of("a", "b", "c"), tos);
        for (Outbound o : out) {
            assertEquals(new EngineEvent.Submitted("a", 1), o.event());
            assertNoCoords(o.event());
        }
    }

    /** TS: it('全员提交后立即结算，不等到时') */
    @Test
    void 全员提交后立即结算不等到时() {
        MeleeEngine e = started();
        fire(e, "a", 9, 9);
        fire(e, "b", 9, 8);
        assertEquals(1, e.view("a").round().intValue());
        List<Outbound> out = fire(e, "c", 9, 7, 500);
        for (String id : IDS) {
            assertEquals(1, of(out, id, EngineEvent.RoundResult.class).size());
            assertEquals(List.of(new EngineEvent.PhaseChanged(GameTypes.GamePhase.PLAYING, 20_500L, null, 2)),
                of(out, id, EngineEvent.PhaseChanged.class));
        }
        assertEquals(2, e.view("a").round().intValue());
        assertEquals(20_500L, e.view("a").deadlineAt().longValue());
        assertEquals(GameTypes.GamePhase.PLAYING, e.phase());
    }

    /** TS: it('一炮落在每个存活对手棋盘上') */
    @Test
    void 一炮落在每个存活对手棋盘上() {
        MeleeEngine e = started();
        fire(e, "a", 6, 6);
        fire(e, "b", 9, 9);
        List<Outbound> out = fire(e, "c", 9, 8);
        EngineEvent.RoundResult ra = of(out, "a", EngineEvent.RoundResult.class).get(0);
        assertEquals(1, ra.round());
        assertEquals(2, ra.shots().size());
        assertContainsShot(ra.shots(), "b", 6, 6, Rules.ShotResult.HEAD, "p0");
        assertContainsShot(ra.shots(), "c", 6, 6, Rules.ShotResult.MISS, "p0");
        assertEquals(List.of(new EngineEvent.DestroyedCount("b", 1)), ra.destroyed());
        assertEquals(1, e.view("b").you().planesDestroyed());
    }

    private static void assertContainsShot(List<GameTypes.TargetShot> shots, String targetId, int row, int col,
                                           Rules.ShotResult result, String planeId) {
        assertTrue(shots.stream().anyMatch(s ->
                s.targetId().equals(targetId) && s.row() == row && s.col() == col
                    && s.result() == result && s.planeId().equals(planeId)),
            "shots 应含 " + targetId + "," + row + "," + col + "," + result + "：" + shots);
    }

    private static void assertContainsIncoming(List<GameTypes.IncomingShot> incoming, String by, int row, int col,
                                               Rules.ShotResult result, String planeId) {
        assertTrue(incoming.stream().anyMatch(s ->
                s.by().equals(by) && s.row() == row && s.col() == col
                    && s.result() == result && s.planeId().equals(planeId)),
            "incoming 应含 " + by + "," + row + "," + col + "," + result + "：" + incoming);
    }

    /** TS: it('roundResult 按人私有：b 只看到打在自己身上的 incoming') */
    @Test
    void roundResult按人私有b只看到打在自己身上的incoming() {
        MeleeEngine e = started();
        fire(e, "a", 5, 5); // b: body，c: miss
        fire(e, "b", 1, 1); // a: body，c: miss
        List<Outbound> out = fire(e, "c", 3, 3); // a: body，b: miss
        EngineEvent.RoundResult rb = of(out, "b", EngineEvent.RoundResult.class).get(0);
        assertEquals(2, rb.incoming().size());
        assertContainsIncoming(rb.incoming(), "a", 5, 5, Rules.ShotResult.BODY, "p0");
        assertContainsIncoming(rb.incoming(), "c", 3, 3, Rules.ShotResult.MISS, "p0");
        assertEquals(2, rb.shots().size());
        assertContainsShot(rb.shots(), "a", 1, 1, Rules.ShotResult.BODY, "p0");
        assertContainsShot(rb.shots(), "c", 1, 1, Rules.ShotResult.MISS, "p0");
        // a 打 c、c 打 a 的结果 b 看不到
        assertFalse(rb.incoming().stream().anyMatch(s -> s.by().equals("c") && s.result() == Rules.ShotResult.BODY),
            "b 不应看到 c 打 a 的 body");
        assertFalse(rb.shots().stream().anyMatch(s -> s.row() == 3 && s.col() == 3),
            "b 的 shots 不应含 c 打 a 的格子");
        assertEquals(List.of(), rb.destroyed());
        assertEquals(List.of(), rb.eliminated());
    }

    /** TS: it('Review Focus #1：发给 a 的所有消息里都没有 b 打 c 的结果') */
    @Test
    void reviewFocus1发给a的所有消息里都没有b打c的结果() {
        // b 的炮全部打在 c 的机身上、却落在 a 的空白处；a、c 的炮选在谁都打不中的地方
        int[][] bShots = {{1, 6}, {1, 8}, {3, 6}, {3, 8}, {2, 6}};
        MeleeEngine e = started();
        List<Outbound> toA = new ArrayList<>();
        for (int i = 0; i < 5; i++) {
            List<Outbound> outs = new ArrayList<>();
            outs.addAll(fire(e, "a", 9, i));
            outs.addAll(fire(e, "b", bShots[i][0], bShots[i][1]));
            outs.addAll(fire(e, "c", 8, i));
            for (Outbound o : outs) if (o.to().equals("a")) toA.add(o);
        }
        List<EngineEvent.RoundResult> results = toA.stream()
            .map(Outbound::event).filter(EngineEvent.RoundResult.class::isInstance)
            .map(EngineEvent.RoundResult.class::cast).toList();
        assertEquals(5, results.size());
        int seen = 0;
        for (Outbound o : toA) {
            EngineEvent ev = o.event();
            if (!(ev instanceof EngineEvent.RoundResult rr)) {
                assertNoCoords(ev);
                continue;
            }
            seen++;
            // shots 只有 a 自己这一炮
            for (GameTypes.TargetShot s : rr.shots()) {
                assertEquals(9, s.row());
                assertEquals(seen - 1, s.col());
            }
            // incoming 只是打在 a 棋盘上的结果（全是 miss），不是打在 c 身上的 body
            for (GameTypes.IncomingShot s : rr.incoming()) assertEquals(Rules.ShotResult.MISS, s.result());
        }
        // b→c 的命中（body）从未出现在发给 a 的任何消息里
        for (Outbound o : toA) {
            assertFalse(String.valueOf(o.event()).contains("BODY"),
                "发给 a 的消息不应含 body：" + o.event());
        }
        // 确认 b→c 确实都是 body（否则上面的断言没有意义）
        List<GameTypes.TargetShot> bToC = e.view("b").you().shots().stream()
            .filter(s -> s.targetId().equals("c")).toList();
        assertEquals(5, bToC.size());
        assertTrue(bToC.stream().allMatch(s -> s.result() == Rules.ShotResult.BODY),
            "b 打 c 应全是 body：" + bToC);
    }

    /** TS: it('同一轮重复提交 → NOT_YOUR_TURN，第一次的坐标不变') */
    @Test
    void 同一轮重复提交NOTYOURTURN第一次的坐标不变() {
        MeleeEngine e = started();
        fire(e, "a", 9, 9);
        List<Outbound> dup = fire(e, "a", 8, 8);
        assertSingleError(dup, "a", GameErrorCode.NOT_YOUR_TURN);
        fire(e, "b", 0, 0);
        List<Outbound> out = fire(e, "c", 0, 1);
        EngineEvent.RoundResult ra = of(out, "a", EngineEvent.RoundResult.class).get(0);
        List<List<Integer>> coords = ra.shots().stream().map(s -> List.of(s.row(), s.col())).toList();
        assertEquals(List.of(List.of(9, 9), List.of(9, 9)), coords);
    }

    /** TS: it('打过的格子 → REPEAT_SHOT；越界 → OUT_OF_RANGE') */
    @Test
    void 打过的格子REPEATSHOT越界OUTOFRANGE() {
        MeleeEngine e = started();
        fire(e, "a", 9, 9);
        fire(e, "b", 0, 0);
        fire(e, "c", 0, 1);
        assertSingleError(fire(e, "a", 9, 9), "a", GameErrorCode.REPEAT_SHOT);
        assertSingleError(fire(e, "a", 10, 0), "a", GameErrorCode.OUT_OF_RANGE);
        assertSingleError(fire(e, "a", 0, 10), "a", GameErrorCode.OUT_OF_RANGE);
        // 被拒后仍可正常提交
        assertEquals(List.of(new EngineEvent.Submitted("a", 2)),
            of(fire(e, "a", 9, 8), "b", EngineEvent.Submitted.class));
    }

    /** TS: it('到时结算：只结算已提交者，未提交者本轮无炮') */
    @Test
    void 到时结算只结算已提交者未提交者本轮无炮() {
        MeleeEngine e = started();
        fire(e, "a", 5, 5);
        assertEquals(List.of(), e.tick(19_999));
        List<Outbound> out = e.tick(20_000);
        EngineEvent.RoundResult ra = of(out, "a", EngineEvent.RoundResult.class).get(0);
        EngineEvent.RoundResult rb = of(out, "b", EngineEvent.RoundResult.class).get(0);
        EngineEvent.RoundResult rc = of(out, "c", EngineEvent.RoundResult.class).get(0);
        assertEquals(2, ra.shots().size());
        assertEquals(List.of(), rb.shots());
        assertEquals(List.of(), rc.shots());
        assertEquals(List.of(new GameTypes.IncomingShot("a", 5, 5, Rules.ShotResult.BODY, "p0")), rb.incoming());
        assertEquals(List.of(new EngineEvent.PhaseChanged(GameTypes.GamePhase.PLAYING, 40_000L, null, 2)),
            of(out, "a", EngineEvent.PhaseChanged.class));
        assertEquals(List.of(), e.view("a").you().incoming());
    }

    /** TS: it('view：others 含 submitted 标记与 planesDestroyed，不含任何坐标') */
    @Test
    void view的others含submitted标记与planesDestroyed不含任何坐标() {
        MeleeEngine e = started();
        fire(e, "a", 9, 9);
        GameTypes.GameView v = e.view("b");
        assertEquals(GameTypes.Mode.MELEE, v.mode());
        assertEquals(GameTypes.GamePhase.PLAYING, v.phase());
        assertNull(v.turn());
        assertEquals(1, v.round().intValue());
        assertEquals(20_000L, v.deadlineAt().longValue());
        assertEquals(List.of(head("b")), v.you().planes());
        assertEquals(List.of(
            new GameTypes.OtherPlayerView("a", true, true, 0, true),
            new GameTypes.OtherPlayerView("c", true, true, 0, false)), v.others());
        for (GameTypes.OtherPlayerView o : v.others()) assertNoCoords(o);
        // 回合结算后 submitted 清零
        fire(e, "b", 0, 0);
        fire(e, "c", 0, 1);
        assertTrue(e.view("b").others().stream().allMatch(o -> !o.submitted()),
            "结算后 submitted 应全部清零");
    }
}
