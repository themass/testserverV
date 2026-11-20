package com.timeline.game.engine;

import com.timeline.game.domain.GameTypes;
import com.timeline.game.domain.Rules;
import com.timeline.game.domain.Ruleset;
import com.timeline.game.protocol.GameErrorCode;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * 镜像 TS apps/server/test/melee-ranking.test.ts：rankPlayers 纯函数 + 出局流程。
 * 3 人：a(2,2) b(6,6) c(2,7)；10×10、1 架、20 秒。
 */
class MeleeRankingTest {

    private static final Ruleset.RuleSet RULES = new Ruleset.RuleSet(10, 1, 20, true);
    private static final List<String> IDS = List.of("a", "b", "c");

    private static List<Rules.Cell> h(int row, int col) { return List.of(new Rules.Cell(row, col)); }

    private static MeleeEngine started(List<Rules.Cell> ha, List<Rules.Cell> hb, List<Rules.Cell> hc,
                                       Ruleset.RuleSet rules) {
        MeleeEngine e = new MeleeEngine(new Engine.EngineOptions(rules, IDS, 0, () -> 0));
        e.handle("a", new Engine.GameCommand.Place(ha), 0);
        e.handle("b", new Engine.GameCommand.Place(hb), 0);
        e.handle("c", new Engine.GameCommand.Place(hc), 0);
        return e;
    }

    /** 默认开局：a(2,2) b(6,6) c(2,7)，10×10 / 1 架 / 20 秒。 */
    private static MeleeEngine started() {
        return started(h(2, 2), h(6, 6), h(2, 7), RULES);
    }

    private static List<Outbound> fire(MeleeEngine e, String id, int row, int col) {
        return fire(e, id, row, col, 100);
    }

    private static List<Outbound> fire(MeleeEngine e, String id, int row, int col, long now) {
        return e.handle(id, new Engine.GameCommand.Fire(row, col), now);
    }

    private static <T extends EngineEvent> List<T> of(List<Outbound> out, String to, Class<T> type) {
        List<T> res = new ArrayList<>();
        for (Outbound o : out) {
            if (o.to().equals(to) && type.isInstance(o.event())) res.add(type.cast(o.event()));
        }
        return res;
    }

    private static void assertSingleError(List<Outbound> out, String to, GameErrorCode code) {
        assertEquals(1, out.size());
        assertEquals(to, out.get(0).to());
        assertInstanceOf(EngineEvent.Error.class, out.get(0).event());
        assertEquals(code, ((EngineEvent.Error) out.get(0).event()).code());
    }

    private static boolean otherAlive(MeleeEngine e, String viewer, String otherId) {
        return e.view(viewer).others().stream().filter(o -> o.playerId().equals(otherId))
            .findFirst().orElseThrow().alive();
    }

    // --------------------------------------------------------------- rankPlayers

    /** 直接构造玩家状态，喂给包内可见的 rankPlayers（TS 里传的是对象字面量）。 */
    private static MeleeEngine.PlayerState ps(String id, Integer eliminatedRound, int hits, boolean midRound) {
        MeleeEngine.PlayerState p = new MeleeEngine.PlayerState(id);
        p.eliminatedRound = eliminatedRound;
        p.hits = hits;
        p.midRound = midRound;
        return p;
    }

    private static MeleeEngine.PlayerState ps(String id, Integer eliminatedRound, int hits) {
        return ps(id, eliminatedRound, hits, false);
    }

    private static List<List<Object>> ranks(List<GameTypes.RankEntry> rs) {
        List<List<Object>> out = new ArrayList<>();
        for (GameTypes.RankEntry r : rs) out.add(List.of(r.playerId(), r.rank()));
        return out;
    }

    /** TS: it('存活者第 1，越晚出局越靠前') */
    @Test
    void 存活者第1越晚出局越靠前() {
        assertEquals(List.of(List.of("b", 1), List.of("c", 2), List.of("a", 3)),
            ranks(MeleeEngine.rankPlayers(List.of(
                ps("a", 2, 3), ps("b", null, 1), ps("c", 5, 0)))));
    }

    /** TS: it('同轮出局按命中数') */
    @Test
    void 同轮出局按命中数() {
        assertEquals(List.of(List.of("a", 1), List.of("b", 2), List.of("c", 3)),
            ranks(MeleeEngine.rankPlayers(List.of(
                ps("a", null, 0), ps("c", 3, 2), ps("b", 3, 4)))));
    }

    /** TS: it('同轮同命中 → 并列，名次跳号') */
    @Test
    void 同轮同命中并列名次跳号() {
        List<GameTypes.RankEntry> r = MeleeEngine.rankPlayers(List.of(
            ps("d", 1, 5), ps("b", 3, 2), ps("a", null, 0), ps("c", 3, 2)));
        assertEquals(List.of(1, 2, 2, 4), r.stream().map(GameTypes.RankEntry::rank).toList());
        assertEquals(List.of("a", "b", "c", "d"), r.stream().map(GameTypes.RankEntry::playerId).toList());
        assertEquals(new GameTypes.RankEntry("d", 4, 1, 5), r.get(3));
    }

    /** TS: it('Review Focus #2：最后两人同轮出局，命中数高者第 1') */
    @Test
    void reviewFocus2最后两人同轮出局命中数高者第1() {
        assertEquals(List.of(List.of("b", 1), List.of("a", 2), List.of("c", 3)),
            ranks(MeleeEngine.rankPlayers(List.of(
                ps("a", 4, 3), ps("b", 4, 5), ps("c", 2, 9)))));
    }

    /** TS: it('Review Focus #2：最后两人同轮出局且命中相同 → 并列第 1，ranking 里至少一个 rank 1') */
    @Test
    void reviewFocus2最后两人同轮出局且命中相同并列第1() {
        List<GameTypes.RankEntry> r = MeleeEngine.rankPlayers(List.of(
            ps("a", 4, 3), ps("b", 4, 3), ps("c", 2, 9)));
        assertEquals(List.of(List.of("a", 1), List.of("b", 1), List.of("c", 3)), ranks(r));
        assertTrue(r.stream().anyMatch(x -> x.rank() == 1));
    }

    // ---------------------------------------------------------------- 出局流程

    /** round 1：a 击中 b 机头，b 出局。返回引擎与本轮结算输出。 */
    private record BIsOut(MeleeEngine e, List<Outbound> out) {}

    private static BIsOut afterBOut() {
        MeleeEngine e = started();
        fire(e, "a", 6, 6);
        fire(e, "b", 9, 9);
        List<Outbound> out = fire(e, "c", 9, 8);
        return new BIsOut(e, out);
    }

    /** TS: it('飞机全灭者在本轮结算后出局，roundResult.eliminated 列出') */
    @Test
    void 飞机全灭者在本轮结算后出局roundResult的eliminated列出() {
        BIsOut r = afterBOut();
        MeleeEngine e = r.e();
        for (String id : IDS) {
            EngineEvent.RoundResult rr = of(r.out(), id, EngineEvent.RoundResult.class).get(0);
            assertEquals(List.of("b"), rr.eliminated());
            assertEquals(List.of(new EngineEvent.DestroyedCount("b", 1)), rr.destroyed());
        }
        // b 本轮那一炮照常结算
        assertEquals(2, of(r.out(), "b", EngineEvent.RoundResult.class).get(0).shots().size());
        assertFalse(otherAlive(e, "a", "b"));
        assertFalse(e.view("b").you().alive());
        assertEquals(GameTypes.GamePhase.PLAYING, e.phase());
        assertEquals(2, e.view("a").round().intValue());
    }

    /** TS: it('出局者之后不再是任何人的目标（下一轮对其的 roundResult.shots 不含其 targetId）') */
    @Test
    void 出局者之后不再是任何人的目标() {
        MeleeEngine e = afterBOut().e();
        int bIncoming = e.view("b").you().incoming().size();
        fire(e, "a", 9, 7);
        List<Outbound> out = fire(e, "c", 9, 6); // 只等存活者，立即结算
        EngineEvent.RoundResult ra = of(out, "a", EngineEvent.RoundResult.class).get(0);
        EngineEvent.RoundResult rc = of(out, "c", EngineEvent.RoundResult.class).get(0);
        assertEquals(List.of("c"), ra.shots().stream().map(GameTypes.TargetShot::targetId).toList());
        assertEquals(List.of("a"), rc.shots().stream().map(GameTypes.TargetShot::targetId).toList());
        // 出局者仍收到公开部分，自己的 shots / incoming 为空
        assertEquals(List.of(new EngineEvent.RoundResult(2, List.of(), List.of(), List.of(), List.of())),
            of(out, "b", EngineEvent.RoundResult.class));
        assertEquals(bIncoming, e.view("b").you().incoming().size());
    }

    /** TS: it('出局者的提交被拒（WRONG_PHASE）') */
    @Test
    void 出局者的提交被拒WRONGPHASE() {
        MeleeEngine e = afterBOut().e();
        assertSingleError(fire(e, "b", 0, 0), "b", GameErrorCode.WRONG_PHASE);
        assertFalse(e.view("a").others().stream().filter(o -> o.playerId().equals("b"))
            .findFirst().orElseThrow().submitted());
    }

    /** TS: it('仅剩 1 人 → gameOver，reason=lastStanding') */
    @Test
    void 仅剩1人gameOver原因lastStanding() {
        MeleeEngine e = afterBOut().e();
        fire(e, "a", 2, 7);
        List<Outbound> out = fire(e, "c", 9, 6, 300);
        assertEquals(GameTypes.GamePhase.FINISHED, e.phase());
        assertEquals(List.of("c"), of(out, "a", EngineEvent.RoundResult.class).get(0).eliminated());
        assertEquals(List.of(), of(out, "a", EngineEvent.PhaseChanged.class));
        List<String> types = out.stream().filter(o -> o.to().equals("a")).map(o -> o.event().getClass().getSimpleName()).toList();
        assertEquals(List.of("Submitted", "RoundResult", "GameOver"), types);
        GameTypes.GameResult result = new GameTypes.GameResult(GameTypes.GameOverReason.LAST_STANDING, List.of(
            new GameTypes.RankEntry("a", 1, null, 2), // r1: b 机头；r2: c 机头（b 已出局，不再是目标）
            new GameTypes.RankEntry("c", 2, 2, 0),
            new GameTypes.RankEntry("b", 3, 1, 0)));
        assertEquals(result, e.result());
        for (String id : IDS) {
            assertEquals(List.of(new EngineEvent.GameOver(result)), of(out, id, EngineEvent.GameOver.class));
        }
        assertNull(e.view("a").deadlineAt());
        assertEquals(List.of(), fire(e, "a", 0, 0));
        assertEquals(List.of(), e.tick(1_000_000));
    }

    /** TS: it('同轮全部出局 → gameOver，reason=lastStanding，按命中数决出第 1') */
    @Test
    void 同轮全部出局gameOver按命中数决出第1() {
        // a(2,2) b(3,7) c(2,7)：a 打 (2,7) = c 机头 + b 机身；b 打 a 机头；c 打 b 机头
        MeleeEngine e = started(h(2, 2), h(3, 7), h(2, 7), RULES);
        fire(e, "a", 2, 7);
        fire(e, "b", 2, 2);
        List<Outbound> out = fire(e, "c", 3, 7);
        assertEquals(GameTypes.GamePhase.FINISHED, e.phase());
        List<String> eliminated = new ArrayList<>(of(out, "a", EngineEvent.RoundResult.class).get(0).eliminated());
        java.util.Collections.sort(eliminated);
        assertEquals(List.of("a", "b", "c"), eliminated);
        assertEquals(new GameTypes.GameResult(GameTypes.GameOverReason.LAST_STANDING, List.of(
            new GameTypes.RankEntry("a", 1, 1, 2),
            new GameTypes.RankEntry("b", 2, 1, 1),
            new GameTypes.RankEntry("c", 2, 1, 1))), e.result());
    }

    /** TS: it('多架飞机：击落一架不出局') */
    @Test
    void 多架飞机击落一架不出局() {
        Ruleset.RuleSet two = new Ruleset.RuleSet(10, 2, 20, true);
        List<Rules.Cell> twoHeads = List.of(new Rules.Cell(2, 2), new Rules.Cell(6, 6));
        MeleeEngine e = started(twoHeads, twoHeads, twoHeads, two);
        fire(e, "a", 2, 2);
        fire(e, "b", 9, 9);
        List<Outbound> out = fire(e, "c", 9, 8);
        EngineEvent.RoundResult rb = of(out, "b", EngineEvent.RoundResult.class).get(0);
        assertEquals(List.of(), rb.eliminated());
        assertEquals(List.of(
            new EngineEvent.DestroyedCount("b", 1),
            new EngineEvent.DestroyedCount("c", 1)), rb.destroyed());
        assertTrue(e.view("b").you().alive());
        assertEquals(GameTypes.GamePhase.PLAYING, e.phase());
    }

    /** TS: it('评审 I3：第 2 轮中途离开者排在同轮结算出局者之后，不会并列或夺得第 1') */
    @Test
    void 评审I3第2轮中途离开者排在同轮结算出局者之后() {
        MeleeEngine e = started();
        fire(e, "a", 5, 5); // b 机身：a 命中 ≥ 1
        fire(e, "b", 8, 0);
        fire(e, "c", 0, 0);
        assertEquals(2, e.view("a").round().intValue());
        e.handle("a", new Engine.GameCommand.Leave(), 200);
        fire(e, "b", 2, 7, 300); // c 机头
        fire(e, "c", 6, 6, 300); // b 机头
        assertEquals(GameTypes.GamePhase.FINISHED, e.phase());
        List<GameTypes.RankEntry> ranking = e.result().ranking();
        GameTypes.RankEntry a = ranking.stream().filter(x -> x.playerId().equals("a")).findFirst().orElseThrow();
        assertEquals(3, a.rank());
        assertEquals(2, a.eliminatedRound().intValue());
        assertEquals(List.of("b", "c"),
            ranking.stream().filter(x -> x.rank() == 1).map(GameTypes.RankEntry::playerId).sorted().toList());
    }
}
