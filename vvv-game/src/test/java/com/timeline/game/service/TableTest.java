package com.timeline.game.service;

import com.timeline.game.domain.GameTypes;
import com.timeline.game.domain.Rules;
import com.timeline.game.domain.Ruleset;
import com.timeline.game.engine.Engine;
import com.timeline.game.engine.EngineEvent;
import com.timeline.game.protocol.GameErrorCode;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.function.DoubleSupplier;

import static org.junit.jupiter.api.Assertions.*;

/**
 * 镜像 TS apps/server/test/table.test.ts（38 例逐条对应；毫秒时间戳与夹具保持一致）。
 *
 * 有意差异（见移植报告）：TS 用 engineFactory 注入 FakeEngine 并可 finish()；
 * Java 的 Table 直接走 Engine.create，无注入口，因此"引擎结束"改由真实引擎的
 * 合法路径驱动——melee 用「连续 3 轮在线不提交 → 全员挂机出局（LAST_STANDING）」，
 * duel 用「掉线超 30s 宽限 → 判负（FORFEIT）」；引擎入参断言改读 Table.lastEngineOptions
 * （startGame 留档，语义等同 TS 的 engineFactory 捕获）。
 */
class TableTest {

    private static final Ruleset.RuleSet RULES = new Ruleset.RuleSet(12, 2, 20, false);
    private static final Ruleset.RuleSet OTHER_RULES = new Ruleset.RuleSet(10, 3, 30, true);
    private static final List<String> IDS = List.of("a", "b", "c", "d");
    private static final DoubleSupplier RNG = () -> 0.5;

    // ---------------------------------------------------------------- 夹具

    private static Table make(GameTypes.TableKind kind, int capacity, long now) {
        return new Table(new Table.Options("123456", kind, capacity, RULES, now, false, null, null, RNG, null));
    }

    private static Table friend(int capacity) { return make(GameTypes.TableKind.FRIEND, capacity, 0); }

    private static void fill(Table t) { fill(t, 4); }
    private static void fill(Table t, int n) {
        for (String id : IDS.subList(0, n)) t.join(id, id.toUpperCase(), 0);
    }
    private static void readyAll(Table t) { readyAll(t, 4); }
    private static void readyAll(Table t, int n) {
        for (String id : IDS.subList(0, n)) t.setReady(id, true, t.rulesVersion(), 0);
    }

    /** melee 桌没有 FakeEngine.finish()：靠"连续 3 轮在线不提交 → 全员挂机出局"结束对局，返回终局 tick 的出站。 */
    private static List<TableOutbound> idleFinishMelee(Table t, long start) {
        t.tick(start + 60_000L);          // 摆放超时：自动落子 + 开局（placeSeconds(12,2)=60s，turn=20s）
        t.tick(start + 80_000L);          // 第 1 轮结算：全员 idle=1
        t.tick(start + 100_000L);         // 第 2 轮结算：idle=2
        return t.tick(start + 120_000L);  // 第 3 轮结算：idle=3 → 全员出局 → finished
    }

    /** duel 桌结束对局的合法路径：掉线超 30s 宽限 → 判负。返回终局 tick 的出站。 */
    private static List<TableOutbound> forfeitDuel(Table t, String victim, long droppedAt) {
        t.setConnected(victim, false, droppedAt);
        return t.tick(droppedAt + Engine.DISCONNECT_GRACE_MS);
    }

    private static GameErrorCode errorOf(List<TableOutbound> out) {
        if (out.isEmpty()) return null;
        return out.get(0).event() instanceof TableEvent.FromEngine fe && fe.event() instanceof EngineEvent.Error e
            ? e.code() : null;
    }
    private static List<String> tos(List<TableOutbound> out) { return out.stream().map(TableOutbound::to).toList(); }
    private static List<String> tosSorted(List<TableOutbound> out) {
        List<String> l = new ArrayList<>(tos(out));
        java.util.Collections.sort(l);
        return l;
    }
    private static List<TableOutbound> tableStatesOf(List<TableOutbound> out) {
        return out.stream().filter(o -> o.event() instanceof TableEvent.TableState).toList();
    }

    // ---------------------------------------------------------------- TS: Table

    @Test
    void 好友房人满且全员准备才开局开局后清空准备() {
        Table t = friend(4);
        fill(t);
        assertNull(t.engine());
        t.setReady("a", true, t.rulesVersion(), 0);
        t.setReady("b", true, t.rulesVersion(), 0);
        t.setReady("c", true, t.rulesVersion(), 0);
        assertNull(t.engine());
        assertEquals(GameTypes.TablePhase.WAITING, t.phase());
        t.setReady("d", true, t.rulesVersion(), 0);
        assertNotNull(t.engine());
        assertTrue(t.view().seats().stream().allMatch(s -> s != null && !s.ready()));
        assertEquals(GameTypes.TablePhase.IN_GAME, t.phase());
    }

    @Test
    void 人未满时全员准备也不开局取消准备生效() {
        Table t = friend(4);
        fill(t, 3);
        readyAll(t, 3);
        assertNull(t.engine());
        t.setReady("a", false, t.rulesVersion(), 0);
        assertFalse(t.view().seats().get(0).ready());
    }

    @Test
    void 引擎以座位顺序的playerIds与当前规则创建() {
        Table t = new Table(new Table.Options("123456", GameTypes.TableKind.FRIEND, 2, RULES, 5, false, null, null, RNG, null));
        t.join("a", "A", 5);
        t.join("b", "B", 5);
        t.setReady("a", true, t.rulesVersion(), 7);
        t.setReady("b", true, t.rulesVersion(), 9);
        assertEquals(List.of("a", "b"), t.lastEngineOptions.playerIds());
        assertEquals(9, t.lastEngineOptions.now());
    }

    @Test
    void 匹配房人满自动开局() {
        Table t = make(GameTypes.TableKind.MATCH, 3, 0);
        t.join("a", "A", 0);
        t.join("b", "B", 0);
        assertNull(t.engine());
        t.join("c", "C", 0);
        assertNotNull(t.engine());
        assertEquals(GameTypes.TablePhase.IN_GAME, t.phase());
    }

    @Test
    void 房主改规则清空所有人准备并广播() {
        Table t = friend(4);
        fill(t);
        t.setReady("b", true, t.rulesVersion(), 0);
        t.setReady("c", true, t.rulesVersion(), 0);
        List<TableOutbound> out = t.updateRules("a", OTHER_RULES, 0);
        assertEquals(IDS, tosSorted(out));
        assertTrue(out.stream().allMatch(o -> o.event() instanceof TableEvent.TableState));
        assertEquals(OTHER_RULES, t.rules());
        assertEquals(OTHER_RULES, t.view().rules());
        assertTrue(t.view().seats().stream().allMatch(s -> s != null && !s.ready()));
    }

    @Test
    void 非房主改规则NOT_HOST匹配房改规则NOT_HOST() {
        Table t = friend(4);
        fill(t);
        List<TableOutbound> out = t.updateRules("b", OTHER_RULES, 0);
        assertEquals(1, out.size());
        assertEquals("b", out.get(0).to());
        assertEquals(GameErrorCode.NOT_HOST, errorOf(out));
        assertEquals(RULES, t.rules());

        Table m = make(GameTypes.TableKind.MATCH, 3, 0);
        m.join("a", "A", 0);
        m.join("b", "B", 0);
        assertEquals(GameErrorCode.NOT_HOST, errorOf(m.updateRules("a", OTHER_RULES, 0)));
        assertEquals(RULES, m.rules());
    }

    @Test
    void 评审焦点3最后一人准备同步开局之后改规则ROOM_IN_GAME引擎用的是开局时的规则() {
        Table t = friend(4);
        fill(t);
        t.updateRules("a", OTHER_RULES, 0);
        readyAll(t);
        assertEquals(OTHER_RULES, t.lastEngineOptions.rules());
        assertEquals(GameErrorCode.ROOM_IN_GAME, errorOf(t.updateRules("a", RULES, 0)));
        assertEquals(OTHER_RULES, t.lastEngineOptions.rules());
        assertEquals(OTHER_RULES, t.rules());
    }

    @Test
    void 对局中加入ROOM_IN_GAME满员加入ROOM_FULL() {
        Table t = friend(3);
        fill(t, 3);
        assertEquals(GameErrorCode.ROOM_FULL, errorOf(t.join("x", "X", 0)));
        readyAll(t, 3);
        List<TableOutbound> out = t.join("x", "X", 0);
        assertEquals(1, out.size());
        assertEquals("x", out.get(0).to());
        assertEquals(GameErrorCode.ROOM_IN_GAME, errorOf(out));
        assertEquals(List.of("a", "b", "c"), t.members());
    }

    @Test
    void 已在座者再次加入只回stateFor() {
        Table t = friend(4);
        fill(t, 2);
        List<TableOutbound> out = t.join("a", "A", 0);
        assertEquals(List.of(t.stateFor("a")), out);
        assertEquals(List.of("a", "b"), t.members());
    }

    @Test
    void join广播tableState给全体在座者含新人昵称被清洗() {
        Table t = friend(4);
        t.join("a", "A", 0);
        List<TableOutbound> out = t.join("b", "  \0Bob  ", 0);
        assertEquals(List.of("a", "b"), tosSorted(out));
        assertInstanceOf(TableEvent.TableState.class, out.get(0).event());
        assertEquals("Bob", t.view().seats().get(1).nickname());
        assertEquals(1, t.view().seats().get(1).seat());
    }

    @Test
    void 空昵称回退为玩家N() {
        Table t = friend(4);
        t.join("a", "", 0);
        assertEquals("玩家1", t.view().seats().get(0).nickname());
    }

    @Test
    void setNickname更新并广播() {
        Table t = friend(4);
        fill(t, 2);
        List<TableOutbound> out = t.setNickname("b", "Zed");
        assertEquals(List.of("a", "b"), tosSorted(out));
        assertEquals("Zed", t.view().seats().get(1).nickname());
    }

    @Test
    void 非成员setReady与updateRules返回NOT_IN_ROOM() {
        Table t = friend(4);
        fill(t, 2);
        assertEquals(GameErrorCode.NOT_IN_ROOM, errorOf(t.setReady("x", true, t.rulesVersion(), 0)));
        assertEquals(GameErrorCode.NOT_IN_ROOM, errorOf(t.updateRules("x", OTHER_RULES, 0)));
    }

    @Test
    void 对局中setReady返回WRONG_PHASE() {
        Table t = make(GameTypes.TableKind.MATCH, 2, 0);
        fill(t, 2);
        assertEquals(GameErrorCode.WRONG_PHASE, errorOf(t.setReady("a", true, t.rulesVersion(), 0)));
    }

    @Test
    void 初始视图房主为首个加入者匹配房无房主() {
        Table t = friend(4);
        assertNull(t.view().hostId());
        fill(t, 2);
        assertEquals("a", t.view().hostId());
        assertEquals(4, t.view().seats().size());
        assertNull(t.view().seats().get(2));
        assertNull(t.view().lastResult());
        // 真人的座位 bot=false（含 null 座位，故用 Arrays.asList）
        assertEquals(java.util.Arrays.asList(false, false, null, null),
            t.view().seats().stream().map(s -> s == null ? null : s.bot()).toList());
        assertEquals(0, t.view().rulesVersion());
        assertFalse(t.view().listed());
        Table m = make(GameTypes.TableKind.MATCH, 2, 0);
        m.join("a", "A", 0);
        assertNull(m.view().hostId());
    }

    @Test
    void handleGame无引擎WRONG_PHASE有引擎则转发() {
        Table t = friend(2);
        fill(t, 2);
        assertEquals(GameErrorCode.WRONG_PHASE, errorOf(t.handleGame("a", new Engine.GameCommand.Fire(0, 0), 0)));
        readyAll(t, 2);
        List<Rules.Cell> heads = List.of(new Rules.Cell(1, 1), new Rules.Cell(1, 7));
        List<TableOutbound> out = t.handleGame("a", new Engine.GameCommand.Place(heads), 42);
        assertEquals("a", out.get(0).to());
        assertInstanceOf(TableEvent.FromEngine.class, out.get(0).event());
        assertEquals(new EngineEvent.PlaneAccepted(heads),
            ((TableEvent.FromEngine) out.get(0).event()).event());
    }

    @Test
    void snapshotFor带上本人的game视图无引擎时game为null() {
        Table t = friend(2);
        fill(t, 2);
        assertNull(t.snapshotFor("a").game());
        assertEquals(new TableOutbound("a", new TableEvent.TableState(t.view())), t.stateFor("a"));
        readyAll(t, 2);
        assertEquals(t.engine().view("a"), t.snapshotFor("a").game());
        assertEquals(t.view(), t.snapshotFor("a").table());
    }

    @Test
    void 引擎结束回到waiting记录lastResult丢弃引擎() {
        Table t = friend(2);
        fill(t, 2);
        readyAll(t, 2);
        List<TableOutbound> out = forfeitDuel(t, "a", 100);
        assertEquals(GameTypes.TablePhase.WAITING, t.phase());
        assertNull(t.engine());
        assertNotNull(t.view().lastResult());
        assertEquals(List.of(), t.view().lastResult().botIds());
        assertEquals(GameTypes.TablePhase.WAITING, t.view().phase());
        assertEquals(List.of("a", "b"), tosSorted(tableStatesOf(out)));
    }

    @Test
    void handleGame与setConnected之后也会检查引擎结束() {
        Table t = friend(2);
        fill(t, 2);
        readyAll(t, 2);
        // duel：对局中的 Leave 即认输 → 引擎结束，由 leaveInGame 的 afterEngine 收口
        t.handleGame("b", new Engine.GameCommand.Leave(), 5);
        assertEquals(GameTypes.TablePhase.WAITING, t.phase());
        t.join("b", "B", 6);
        t.setReady("a", true, t.rulesVersion(), 6);
        t.setReady("b", true, t.rulesVersion(), 6);
        assertEquals(GameTypes.TablePhase.IN_GAME, t.phase());
        // 掉线超宽限后重连：setConnected 当场判负，afterEngine 收口
        t.setConnected("a", false, 7);
        t.setConnected("a", true, 7 + Engine.DISCONNECT_GRACE_MS);
        assertEquals(GameTypes.TablePhase.WAITING, t.phase());
    }

    @Test
    void 下一局开始时lastResult清空引擎是新建的() {
        Table t = friend(2);
        fill(t, 2);
        readyAll(t, 2);
        Engine first = t.engine();
        forfeitDuel(t, "a", 1);
        assertNotNull(t.view().lastResult());
        Table.LastGame last = t.lastGame();
        assertNotNull(last);
        assertEquals(t.tableId() + ":0", last.id());
        assertEquals(GameTypes.Mode.DUEL, last.mode());
        assertNull(last.preset());
        assertEquals(List.of("a", "b"), last.humans());
        t.setReady("a", true, t.rulesVersion(), 2);
        t.setReady("b", true, t.rulesVersion(), 2);
        assertNotSame(first, t.engine());
        assertNull(t.view().lastResult());
        assertEquals(GameTypes.TablePhase.IN_GAME, t.phase());
    }

    @Test
    void tick在对局中转发给引擎并带出其输出() {
        Table t = friend(2);
        fill(t, 2);
        readyAll(t, 2);
        // 摆放超时（60s）→ 引擎自动落子的 planeAccepted + 开局的 phaseChanged，均经桌子透出
        List<TableOutbound> out = t.tick(60_000);
        assertEquals(4, out.size());
        assertEquals(List.of("a", "b"), tos(out.subList(0, 2)));
        assertTrue(out.subList(0, 2).stream().allMatch(o -> o.event() instanceof TableEvent.FromEngine fe
            && fe.event() instanceof EngineEvent.PlaneAccepted));
        assertTrue(out.subList(2, 4).stream().allMatch(o -> o.event() instanceof TableEvent.FromEngine fe
            && fe.event() instanceof EngineEvent.PhaseChanged));
    }

    @Test
    void 房主在等候室离开房主转给最小座位号() {
        Table t = friend(4);
        fill(t);
        List<TableOutbound> out = t.leave("a", 0);
        assertEquals("b", t.view().hostId());
        assertNull(t.view().seats().get(0));
        assertEquals(List.of("b", "c", "d"), t.members());
        assertEquals(List.of("b", "c", "d"), tosSorted(tableStatesOf(out)));
        // 座位空出后由下一个加入者补最小空位
        t.join("e", "E", 0);
        assertEquals("e", t.view().seats().get(0).playerId());
        assertEquals("b", t.view().hostId());
    }

    @Test
    void 等候室非成员leave返回空() {
        Table t = friend(4);
        fill(t, 2);
        assertEquals(List.of(), t.leave("x", 0));
    }

    @Test
    void 匹配房打完一局后有人离开其余人收到roomClosed并关闭() {
        Table t = make(GameTypes.TableKind.MATCH, 3, 0);
        fill(t, 3); // 匹配房人满自动开局
        idleFinishMelee(t, 0);
        assertFalse(t.closed());
        List<TableOutbound> out = t.leave("c", 120_001);
        assertTrue(t.closed());
        assertEquals(List.of("a", "b"), tosSorted(out.stream()
            .filter(o -> o.event() instanceof TableEvent.Closed).toList()));
    }

    @Test
    void 好友房打完一局后有人离开只释放座位不关桌() {
        Table t = friend(3);
        fill(t, 3);
        readyAll(t, 3);
        idleFinishMelee(t, 0);
        List<TableOutbound> out = t.leave("c", 120_001);
        assertFalse(t.closed());
        assertTrue(out.stream().noneMatch(o -> o.event() instanceof TableEvent.Closed));
        assertEquals(List.of("a", "b"), t.members());
    }

    @Test
    void 匹配房首局开始前有人离开只释放座位不关桌() {
        Table t = make(GameTypes.TableKind.MATCH, 3, 0);
        t.join("a", "A", 0);
        t.join("b", "B", 0);
        t.leave("b", 1);
        assertFalse(t.closed());
        assertEquals(List.of("a"), t.members());
    }

    @Test
    void 裁定R2好友房里还有别人在座时掉线者60秒后让出座位59秒内回来保留() {
        Table t = friend(4);
        fill(t, 2);
        t.setConnected("b", false, 1000);
        assertFalse(t.view().seats().get(1).connected());
        t.tick(1000 + Table.MATCH_SEAT_GRACE_MS - 1);
        assertEquals(List.of("a", "b"), t.members());
        t.tick(1000 + Table.MATCH_SEAT_GRACE_MS);
        assertEquals(List.of("a"), t.members());

        t.join("c", "C", 400_000);
        t.setConnected("c", false, 400_000);
        t.tick(400_000 + Table.MATCH_SEAT_GRACE_MS - 1);
        t.setConnected("c", true, 400_000 + Table.MATCH_SEAT_GRACE_MS - 1);
        assertTrue(t.view().seats().get(1).connected());
        t.tick(400_000 + Table.FRIEND_SEAT_GRACE_MS * 3);
        assertEquals(List.of("a", "c"), t.members());
    }

    @Test
    void 裁定R2掉线者是唯一在座者座位保留5分钟() {
        Table t = friend(4);
        t.join("a", "A", 0);
        t.setConnected("a", false, 1000);
        t.tick(1000 + Table.MATCH_SEAT_GRACE_MS);
        t.tick(1000 + Table.FRIEND_SEAT_GRACE_MS - 1);
        assertEquals(List.of("a"), t.members());
        assertFalse(t.closed());
        t.tick(1000 + Table.FRIEND_SEAT_GRACE_MS);
        assertTrue(t.closed());
    }

    @Test
    void 宽限常量取值() {
        assertEquals(300_000, Table.FRIEND_SEAT_GRACE_MS);
        assertEquals(60_000, Table.MATCH_SEAT_GRACE_MS);
    }

    @Test
    void 匹配房等候室掉线60秒后让出座位59秒内回来保留() {
        Table t = make(GameTypes.TableKind.MATCH, 3, 0);
        t.join("a", "A", 0);
        t.join("b", "B", 0);
        t.setConnected("b", false, 1000);
        t.tick(1000 + Table.MATCH_SEAT_GRACE_MS - 1000);
        assertEquals(List.of("a", "b"), t.members());
        t.tick(1000 + Table.MATCH_SEAT_GRACE_MS);
        assertEquals(List.of("a"), t.members());

        t.join("c", "C", 100_000);
        t.setConnected("c", false, 100_000);
        t.setConnected("c", true, 159_000);
        t.tick(100_000 + Table.MATCH_SEAT_GRACE_MS * 5);
        assertEquals(List.of("a", "c"), t.members());
    }

    @Test
    void 匹配房打完一局后等候室掉线超时视同离开关桌() {
        Table t = make(GameTypes.TableKind.MATCH, 2, 0);
        fill(t, 2); // 自动开局（duel）
        forfeitDuel(t, "a", 100);   // 引擎结束：a 掉线判负
        t.setConnected("a", true, 30_200); // 回来后进入等候室
        t.setConnected("b", false, 40_000);
        List<TableOutbound> out = t.tick(40_000 + Table.MATCH_SEAT_GRACE_MS);
        assertTrue(t.closed());
        assertEquals(List.of("a"), tos(out.stream()
            .filter(o -> o.event() instanceof TableEvent.Closed).toList()));
    }

    @Test
    void 所有人离开则关闭() {
        Table t = friend(4);
        fill(t, 2);
        t.leave("a", 0);
        assertFalse(t.closed());
        t.leave("b", 0);
        assertTrue(t.closed());
        assertEquals(List.of(), t.members());
    }

    @Test
    void 关闭后的桌子拒绝加入() {
        Table t = friend(4);
        t.join("a", "A", 0);
        t.leave("a", 0);
        assertEquals(GameErrorCode.ROOM_NOT_FOUND, errorOf(t.join("b", "B", 0)));
    }

    @Test
    void 对局中leave转发给引擎座位到本局结束才释放() {
        Table t = friend(3);
        fill(t, 3);
        readyAll(t, 3);
        List<TableOutbound> out = t.leave("c", 50);
        // 转发进引擎：melee 当场出局（playerOut 透出）
        assertTrue(out.stream().anyMatch(o -> o.to().equals("c") && o.event() instanceof TableEvent.FromEngine fe
            && fe.event() instanceof EngineEvent.PlayerOut po && po.playerId().equals("c")));
        assertNotNull(t.view().seats().get(2));
        assertEquals(List.of("a", "b", "c"), t.members());
        assertEquals(GameTypes.TablePhase.IN_GAME, t.phase());
        // 本局结束时释放
        idleFinishMelee(t, 0);
        assertNull(t.view().seats().get(2));
        assertEquals(List.of("a", "b"), t.members());
        assertFalse(t.closed());
    }

    @Test
    void 对局中收到leaveRoom命令等同leave() {
        Table t = friend(3);
        fill(t, 3);
        readyAll(t, 3);
        List<TableOutbound> out = t.handleGame("b", new Engine.GameCommand.Leave(), 9);
        // 引擎收到了一次认输：出局广播只有 b 一人（发给全体 3 个在座者）
        assertEquals(3, out.stream().filter(o -> o.event() instanceof TableEvent.FromEngine fe
            && fe.event() instanceof EngineEvent.PlayerOut po && po.playerId().equals("b")).count());
        // 本局结束时释放
        idleFinishMelee(t, 0);
        assertEquals(List.of("a", "c"), t.members());
    }

    @Test
    void 对局中离开的人不再收到后续tableState广播匹配房结束后关桌() {
        Table t = make(GameTypes.TableKind.MATCH, 3, 0);
        fill(t, 3); // 自动开局
        t.leave("c", 5);
        List<TableOutbound> out = idleFinishMelee(t, 0);
        assertTrue(t.closed());
        assertEquals(List.of("a", "b"), tosSorted(out.stream()
            .filter(o -> o.event() instanceof TableEvent.Closed).toList()));
        assertTrue(out.stream().noneMatch(o -> o.to().equals("c")
            && (o.event() instanceof TableEvent.TableState || o.event() instanceof TableEvent.Closed)));
    }

    @Test
    void 对局中全员离开且引擎结束则关闭() {
        Table t = friend(2);
        fill(t, 2);
        readyAll(t, 2);
        t.leave("a", 1); // duel：leave 即认输，引擎随即结束；b 的座位留桌
        t.leave("b", 2); // 桌上再无真人 → 静默关桌
        assertTrue(t.closed());
    }

    @Test
    void 对局中setConnected转发给引擎并更新座位连接状态() {
        Table t = friend(2);
        fill(t, 2);
        readyAll(t, 2);
        List<TableOutbound> out = t.setConnected("b", false, 33);
        // 转发进引擎：presence + paused 透出，座位状态更新，桌子广播照常
        assertTrue(out.stream().anyMatch(o -> o.event() instanceof TableEvent.FromEngine fe
            && fe.event() instanceof EngineEvent.Presence p
            && p.playerId().equals("b") && !p.connected()));
        assertFalse(t.view().seats().get(1).connected());
        assertFalse(tableStatesOf(out).isEmpty());
        // 对局中不会因为掉线而释放座位（这里宽限判负也发生在引擎内，座位仍留桌）
        t.tick(33 + Table.FRIEND_SEAT_GRACE_MS * 10);
        assertEquals(List.of("a", "b"), t.members());
    }
}
