package com.timeline.game.engine;

import com.timeline.game.domain.GameTypes;
import com.timeline.game.domain.Rules;
import com.timeline.game.domain.Ruleset;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * 镜像 TS apps/server/test/melee-presence.test.ts：MeleeEngine 超时 / 挂机 / 掉线 / 离开。
 * 3 人：a(2,2) b(6,6) c(2,7)；10×10、1 架、20 秒。
 */
class MeleePresenceTest {

    private static final Ruleset.RuleSet RULES = new Ruleset.RuleSet(10, 1, 20, true);
    private static final List<String> IDS = List.of("a", "b", "c");
    private static final List<Rules.Cell> HEAD_A = List.of(new Rules.Cell(2, 2));
    private static final List<Rules.Cell> HEAD_B = List.of(new Rules.Cell(6, 6));
    private static final List<Rules.Cell> HEAD_C = List.of(new Rules.Cell(2, 7));

    /** 每人一行谁都打不中的格子：第 n 轮打 (ROW[id], n-1)。 */
    private static int row(String id) {
        return switch (id) {
            case "a" -> 9;
            case "b" -> 8;
            case "c" -> 0;
            default -> throw new IllegalArgumentException(id);
        };
    }

    private static MeleeEngine fresh() {
        return new MeleeEngine(new Engine.EngineOptions(RULES, IDS, 0, () -> 0));
    }

    /** 摆放完毕：round 1，deadline = 20_000。 */
    private static MeleeEngine started() {
        MeleeEngine e = fresh();
        e.handle("a", new Engine.GameCommand.Place(HEAD_A), 0);
        e.handle("b", new Engine.GameCommand.Place(HEAD_B), 0);
        e.handle("c", new Engine.GameCommand.Place(HEAD_C), 0);
        return e;
    }

    /** 按 ROW 表打本轮的格子。 */
    private static List<Outbound> fire(MeleeEngine e, String id, long now) {
        int round = e.view(id).round();
        return e.handle(id, new Engine.GameCommand.Fire(row(id), round - 1), now);
    }

    private static <T extends EngineEvent> List<T> of(List<Outbound> out, String to, Class<T> type) {
        List<T> res = new ArrayList<>();
        for (Outbound o : out) {
            if (o.to().equals(to) && type.isInstance(o.event())) res.add(type.cast(o.event()));
        }
        return res;
    }

    private static boolean alive(MeleeEngine e, String id) {
        return e.view(id).you().alive();
    }

    /** shooters 提交后走到本轮 deadline 结算，返回结算输出。 */
    private static List<Outbound> playRound(MeleeEngine e, List<String> shooters) {
        long dl = e.view("b").deadlineAt().longValue();
        for (String id : shooters) fire(e, id, dl - 1000);
        // TS 的 playRound 只返回 tick 的输出；fire 期间的广播（submitted 等）不返回
        return e.tick(dl);
    }

    // ------------------------------------------------------------------ tests

    /** TS: it('超时未提交：本轮无炮，不代打') */
    @Test
    void 超时未提交本轮无炮不代打() {
        MeleeEngine e = started();
        fire(e, "b", 100);
        fire(e, "c", 100);
        assertEquals(List.of(), e.tick(19_999));
        List<Outbound> out = e.tick(20_000);
        assertEquals(List.of(), of(out, "a", EngineEvent.RoundResult.class).get(0).shots());
        assertEquals(List.of("c"),
            of(out, "b", EngineEvent.RoundResult.class).get(0).incoming().stream()
                .map(GameTypes.IncomingShot::by).toList());
        assertEquals(List.of(), e.view("a").you().shots());
        assertTrue(alive(e, "a"));
    }

    /** TS: it('连续 3 轮在线未提交 → 出局；中间提交一次则重新计数') */
    @Test
    void 连续3轮在线未提交出局中间提交一次则重新计数() {
        MeleeEngine e = started();
        playRound(e, List.of("b", "c"));            // r1 a idle 1
        playRound(e, List.of("b", "c"));            // r2 a idle 2
        playRound(e, List.of("a", "b", "c"));       // r3 a 提交 → 0（全员提交，立即结算）
        assertEquals(4, e.view("a").round().intValue());
        playRound(e, List.of("b", "c"));            // r4 idle 1
        playRound(e, List.of("b", "c"));            // r5 idle 2
        assertTrue(alive(e, "a"));
        List<Outbound> out = playRound(e, List.of("b", "c")); // r6 idle 3 → 出局
        EngineEvent.RoundResult rb = of(out, "b", EngineEvent.RoundResult.class).get(0);
        assertEquals(6, rb.round());
        assertEquals(List.of("a"), rb.eliminated());
        assertFalse(alive(e, "a"));
        assertEquals(GameTypes.GamePhase.PLAYING, e.phase());
    }

    /** TS: it('掉线不暂停：其他人照常进行，phase 仍为 playing') */
    @Test
    void 掉线不暂停其他人照常进行phase仍为playing() {
        MeleeEngine e = started();
        List<Outbound> out = e.setConnected("a", false, 100);
        assertEquals(List.of(
            new Outbound("b", new EngineEvent.Presence("a", false)),
            new Outbound("c", new EngineEvent.Presence("a", false))), out);
        assertEquals(GameTypes.GamePhase.PLAYING, e.phase());
        assertEquals(20_000L, e.view("b").deadlineAt().longValue());
        assertFalse(e.view("b").others().stream().filter(o -> o.playerId().equals("a"))
            .findFirst().orElseThrow().connected());
        List<Outbound> r = e.tick(20_000);
        assertEquals(List.of(new EngineEvent.PhaseChanged(GameTypes.GamePhase.PLAYING, 40_000L, null, 2)),
            of(r, "b", EngineEvent.PhaseChanged.class));
        assertEquals(GameTypes.GamePhase.PLAYING, e.phase());
    }

    /** TS: it('掉线期间不计挂机：掉线 25 秒（跨 2 轮）后回来，idle 计数为 0') */
    @Test
    void 掉线期间不计挂机掉线25秒后回来idle计数为0() {
        MeleeEngine e = started();
        e.setConnected("a", false, 1_000);
        fire(e, "b", 10_000);
        fire(e, "c", 10_000); // 在线存活者已齐 → r1 立即结算
        fire(e, "b", 20_000);
        fire(e, "c", 20_000); // r2 立即结算
        assertEquals(3, e.view("b").round().intValue());
        assertEquals(List.of(
            new Outbound("b", new EngineEvent.Presence("a", true)),
            new Outbound("c", new EngineEvent.Presence("a", true))), e.setConnected("a", true, 26_000));
        playRound(e, List.of("b", "c")); // r3 idle 1
        playRound(e, List.of("b", "c")); // r4 idle 2 —— 若掉线期间也计数，这里早已出局
        assertTrue(alive(e, "a"));
        List<Outbound> out = playRound(e, List.of("b", "c")); // r5 idle 3
        EngineEvent.RoundResult ra = of(out, "a", EngineEvent.RoundResult.class).get(0);
        assertEquals(5, ra.round());
        assertEquals(List.of("a"), ra.eliminated());
        assertFalse(alive(e, "a"));
    }

    /** TS: it('掉线满 30 秒 → 出局') */
    @Test
    void 掉线满30秒出局() {
        MeleeEngine e = started();
        e.setConnected("a", false, 1_000);
        e.tick(20_000); // r1 超时结算，r2 deadline 40_000
        e.tick(30_999);
        assertTrue(alive(e, "a"));
        e.tick(31_000);
        assertFalse(alive(e, "a"));
        assertFalse(e.view("b").others().stream().filter(o -> o.playerId().equals("a"))
            .findFirst().orElseThrow().alive());
        assertEquals(GameTypes.GamePhase.PLAYING, e.phase());
        // 出局在本轮 roundResult 里公开；之后不再是目标
        fire(e, "b", 32_000);
        List<Outbound> out = fire(e, "c", 32_000);
        EngineEvent.RoundResult rb = of(out, "b", EngineEvent.RoundResult.class).get(0);
        assertEquals(2, rb.round());
        assertEquals(List.of("a"), rb.eliminated());
        assertEquals(List.of("c"), rb.shots().stream().map(GameTypes.TargetShot::targetId).toList());

        // 宽限已过、tick 还没判就重连：同样出局
        MeleeEngine e2 = started();
        e2.setConnected("a", false, 1_000);
        e2.setConnected("a", true, 31_500);
        assertFalse(alive(e2, "a"));
    }

    /** TS: it('Review Focus #5：提交后立刻掉线，本轮那一炮仍然结算') */
    @Test
    void reviewFocus5提交后立刻掉线本轮那一炮仍然结算() {
        MeleeEngine e = started();
        e.handle("a", new Engine.GameCommand.Fire(5, 5), 100); // b 机身
        e.setConnected("a", false, 200);
        fire(e, "b", 300);
        List<Outbound> out = fire(e, "c", 400);
        EngineEvent.RoundResult rb = of(out, "b", EngineEvent.RoundResult.class).get(0);
        assertTrue(rb.incoming().contains(new GameTypes.IncomingShot("a", 5, 5, Rules.ShotResult.BODY, "p0")),
            "b 的 incoming 应含 a 的 body：" + rb.incoming());
        assertEquals(2, of(out, "a", EngineEvent.RoundResult.class).get(0).shots().size());
        assertEquals(2, e.view("a").you().shots().size());
    }

    /** TS: it('本轮所有在线存活者都已提交、掉线者未提交 → 立即结算，不等掉线者') */
    @Test
    void 在线存活者已提交而掉线者未提交立即结算不等掉线者() {
        MeleeEngine e = started();
        e.setConnected("a", false, 100);
        fire(e, "b", 200);
        List<Outbound> out = fire(e, "c", 500);
        assertEquals(1, of(out, "b", EngineEvent.RoundResult.class).size());
        assertEquals(List.of(new EngineEvent.PhaseChanged(GameTypes.GamePhase.PLAYING, 20_500L, null, 2)),
            of(out, "b", EngineEvent.PhaseChanged.class));

        // 反过来：在线者都已提交后，最后一个未提交者掉线 → 当场结算
        MeleeEngine e2 = started();
        fire(e2, "b", 200);
        fire(e2, "c", 300);
        List<Outbound> out2 = e2.setConnected("a", false, 700);
        assertEquals(1, of(out2, "b", EngineEvent.Presence.class).size());
        assertEquals(1, of(out2, "b", EngineEvent.RoundResult.class).size());
        assertEquals(2, e2.view("b").round().intValue());
    }

    /** TS: it('摆放阶段掉线不暂停，到时自动摆放') */
    @Test
    void 摆放阶段掉线不暂停到时自动摆放() {
        MeleeEngine e = fresh(); // placing deadline = 45_000
        e.handle("a", new Engine.GameCommand.Place(HEAD_A), 0);
        e.handle("b", new Engine.GameCommand.Place(HEAD_B), 0);
        assertEquals(List.of(new EngineEvent.Presence("c", false)),
            of(e.setConnected("c", false, 20_000), "a", EngineEvent.Presence.class));
        assertEquals(GameTypes.GamePhase.PLACING, e.phase());
        assertEquals(45_000L, e.view("a").deadlineAt().longValue());
        assertEquals(List.of(), e.tick(44_999));
        List<Outbound> out = e.tick(45_000);
        assertEquals(1, of(out, "c", EngineEvent.PlaneAccepted.class).size());
        assertEquals(List.of(), of(out, "a", EngineEvent.PlaneAccepted.class));
        assertEquals(List.of(new EngineEvent.PhaseChanged(GameTypes.GamePhase.PLAYING, 65_000L, null, 1)),
            of(out, "a", EngineEvent.PhaseChanged.class));
        assertEquals(GameTypes.GamePhase.PLAYING, e.phase());
        assertTrue(alive(e, "c"));
    }

    /** TS: it('leaveRoom → 当场出局；只剩 1 人 → gameOver') */
    @Test
    void leaveRoom当场出局只剩1人gameOver() {
        MeleeEngine e = started();
        fire(e, "b", 100);
        fire(e, "c", 100);
        // a 是唯一未提交者：离开后在线存活者已齐 → 本轮当场结算
        List<Outbound> out1 = e.handle("a", new Engine.GameCommand.Leave(), 200);
        assertFalse(alive(e, "a"));
        EngineEvent.RoundResult rb1 = of(out1, "b", EngineEvent.RoundResult.class).get(0);
        assertEquals(1, rb1.round());
        assertEquals(List.of("a"), rb1.eliminated());
        assertEquals(List.of("c"), rb1.shots().stream().map(GameTypes.TargetShot::targetId).toList());
        assertEquals(GameTypes.GamePhase.PLAYING, e.phase());

        List<Outbound> out2 = e.handle("b", new Engine.GameCommand.Leave(), 300); // round 2
        assertEquals(GameTypes.GamePhase.FINISHED, e.phase());
        GameTypes.GameResult result = new GameTypes.GameResult(GameTypes.GameOverReason.LAST_STANDING, List.of(
            new GameTypes.RankEntry("c", 1, null, 0),
            new GameTypes.RankEntry("b", 2, 2, 0),
            new GameTypes.RankEntry("a", 3, 1, 0)));
        assertEquals(result, e.result());
        assertEquals(List.of(new EngineEvent.GameOver(result)), of(out2, "c", EngineEvent.GameOver.class));
    }

    /** TS: it('重连收到 state（view），其中 round 与 deadlineAt 为当前值') */
    @Test
    void 重连收到view其中round与deadlineAt为当前值() {
        MeleeEngine e = started();
        e.setConnected("a", false, 100);
        e.tick(20_000); // → r2，deadline 40_000
        fire(e, "b", 22_000);
        List<Outbound> out = e.setConnected("a", true, 25_000);
        assertEquals(List.of("b", "c"), out.stream().map(Outbound::to).toList());
        assertTrue(out.stream().allMatch(o -> o.event() instanceof EngineEvent.Presence));
        GameTypes.GameView v = e.view("a");
        assertEquals(GameTypes.Mode.MELEE, v.mode());
        assertEquals(GameTypes.GamePhase.PLAYING, v.phase());
        assertEquals(2, v.round().intValue());
        assertEquals(40_000L, v.deadlineAt().longValue());
        assertNull(v.turn());
        assertTrue(v.you().alive());
        assertTrue(e.view("a").others().stream().filter(o -> o.playerId().equals("b"))
            .findFirst().orElseThrow().submitted());
    }

    /** TS: it('评审 I2：提交后掉线、回合结束前宽限到期出局 → 那一炮仍然落在 b、c 棋盘上') */
    @Test
    void 评审I2提交后掉线宽限到期出局那一炮仍然落在bc棋盘上() {
        MeleeEngine e = new MeleeEngine(new Engine.EngineOptions(
            new Ruleset.RuleSet(10, 1, 60, true), IDS, 0, () -> 0));
        e.handle("a", new Engine.GameCommand.Place(HEAD_A), 0);
        e.handle("b", new Engine.GameCommand.Place(HEAD_B), 0);
        e.handle("c", new Engine.GameCommand.Place(HEAD_C), 0);
        e.handle("a", new Engine.GameCommand.Fire(5, 5), 100); // b 机身
        e.setConnected("a", false, 200);
        e.tick(200 + 30_000);
        assertFalse(alive(e, "a"));
        fire(e, "b", 31_000);
        List<Outbound> out = fire(e, "c", 31_000);
        EngineEvent.RoundResult rb = of(out, "b", EngineEvent.RoundResult.class).get(0);
        assertEquals(1, rb.round());
        assertEquals(List.of("a"), rb.eliminated());
        assertTrue(rb.incoming().contains(new GameTypes.IncomingShot("a", 5, 5, Rules.ShotResult.BODY, "p0")),
            "b 的 incoming 应含 a 的 body：" + rb.incoming());
        assertTrue(of(out, "c", EngineEvent.RoundResult.class).get(0).incoming().stream()
            .map(GameTypes.IncomingShot::by).anyMatch(by -> by.equals("a")),
            "c 的 incoming 应含 a 的炮");
        List<String> aTargets = new ArrayList<>(e.view("a").you().shots().stream()
            .map(GameTypes.TargetShot::targetId).toList());
        java.util.Collections.sort(aTargets);
        assertEquals(List.of("b", "c"), aTargets);
        // a 已出局，不再是目标
        assertEquals(List.of("c"), rb.shots().stream().map(GameTypes.TargetShot::targetId).toList());
    }

    /** TS: it('评审 I2：提交后 leaveRoom，那一炮同样在本轮结算') */
    @Test
    void 评审I2提交后leaveRoom那一炮同样在本轮结算() {
        MeleeEngine e = started();
        e.handle("a", new Engine.GameCommand.Fire(5, 5), 100);
        e.handle("a", new Engine.GameCommand.Leave(), 150);
        fire(e, "b", 200);
        List<Outbound> out = fire(e, "c", 300);
        EngineEvent.RoundResult rb = of(out, "b", EngineEvent.RoundResult.class).get(0);
        assertTrue(rb.incoming().contains(new GameTypes.IncomingShot("a", 5, 5, Rules.ShotResult.BODY, "p0")),
            "b 的 incoming 应含 a 的 body：" + rb.incoming());
    }
}
