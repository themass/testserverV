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
import java.util.Optional;
import java.util.function.DoubleSupplier;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;

/**
 * 镜像 TS apps/server/test/table-kick.test.ts（规则版本 M4 + 房主踢人）
 * 与 table-listing.test.ts（大厅列表投影 + setListed），毫秒时间戳与夹具保持一致。
 *
 * 有意差异（见移植报告）：
 * - 无 engineFactory 注入：TS 的 FakeEngine 省略，结束路径改用真实引擎语义；
 * - bot id 生成归 GameBot 工厂（GameBot.playerId() 契约自带 id），桌子不再自造
 *   bot:{roomCode}:{index}:{seq}——测试工厂照 TS 格式产 id，断言不变；
 * - 电脑"收不到消息"验证桌边界过滤（spec §2 / table.ts:439），真实思考大脑后补。
 */
class TableKickListingTest {

    private static final Ruleset.RuleSet RULES = new Ruleset.RuleSet(12, 2, 20, false);
    private static final Ruleset.RuleSet OTHER_RULES = new Ruleset.RuleSet(10, 3, 30, true);
    private static final List<String> IDS = List.of("a", "b", "c", "d");
    private static final DoubleSupplier RNG = () -> 0.5;

    // ---------------------------------------------------------------- 夹具

    /** 桩电脑：只保证 id 契约（bot: 前缀），永不行动（思考大脑后续移植）。 */
    private static GameBot stubBot(String id) {
        return new GameBot() {
            @Override public String playerId() { return id; }
            @Override public Optional<Engine.GameCommand> poll(GameTypes.GameView view, Ruleset.RuleSet rules, long now) {
                return Optional.empty();
            }
        };
    }

    /** TS 格式的 bot id 工厂：bot:{roomCode}:{seatIndex}:{递增序号}。 */
    private static java.util.function.BiFunction<String, Integer, GameBot> botFactory(String roomCode) {
        AtomicInteger seq = new AtomicInteger();
        return (difficulty, seat) -> stubBot("bot:" + roomCode + ":" + seat + ":" + seq.incrementAndGet());
    }

    /** 会动手的桩电脑：摆放阶段补一个合法摆放；playing 且本轮未提交则固定开一炮（每键只动作一次）。 */
    private static GameBot placingBot(String id, int headRow, int headCol) {
        List<Rules.Cell> heads = List.of(new Rules.Cell(headRow, headCol), new Rules.Cell(9, headCol));
        boolean[] placed = {false};
        int[] firedRound = {-1};
        return new GameBot() {
            @Override public String playerId() { return id; }
            @Override public Optional<Engine.GameCommand> poll(GameTypes.GameView view, Ruleset.RuleSet rules, long now) {
                if (view.phase() == GameTypes.GamePhase.PLACING && !placed[0]) {
                    placed[0] = true;
                    return Optional.of(new Engine.GameCommand.Place(heads));
                }
                if (view.phase() == GameTypes.GamePhase.PLAYING && !view.you().submitted()
                    && view.round() != null && view.round() != firedRound[0]) {
                    firedRound[0] = view.round();
                    return Optional.of(new Engine.GameCommand.Fire(0, view.round() - 1));
                }
                return Optional.empty();
            }
        };
    }

    private static Table make(String roomCode, GameTypes.TableKind kind, int capacity, long now, boolean listed,
                              java.util.function.BiFunction<String, Integer, GameBot> factory, String tableId) {
        return new Table(new Table.Options(roomCode, kind, capacity, RULES, now, listed, tableId, factory, RNG, null));
    }

    private static Table make() { return make("123456", GameTypes.TableKind.FRIEND, 4, 0, false, null, null); }
    private static Table make(java.util.function.BiFunction<String, Integer, GameBot> factory) {
        return make("123456", GameTypes.TableKind.FRIEND, 4, 0, false, factory, null);
    }
    /** listing.test.ts 的 make：tableId 固定 abcd1234abcd1234，now=1000。 */
    private static Table listedRoom(String roomCode, GameTypes.TableKind kind, int capacity, long now, boolean listed) {
        return make(roomCode, kind, capacity, now, listed, null, "abcd1234abcd1234");
    }

    private static void fill(Table t) { fill(t, 4); }
    private static void fill(Table t, int n) {
        for (String id : IDS.subList(0, n)) t.join(id, id.toUpperCase(), 0);
    }
    /** listing.test.ts 的 fill：昵称"昵称{id}"，now=1000。 */
    private static void fillListed(Table t, int n) {
        for (String id : IDS.subList(0, n)) t.join(id, "昵称" + id, 1000);
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
    /** 取出出站里的 tableState（保留收件人，便于断言"谁收到了什么"）。 */
    private static List<TableOutbound> statesOf(List<TableOutbound> out) {
        return out.stream().filter(o -> o.event() instanceof TableEvent.TableState).toList();
    }
    private static GameTypes.TableView stateOf(TableOutbound o) {
        return ((TableEvent.TableState) o.event()).table();
    }
    /** 出站流里绝不允许出现 bot 收件人（桌边界过滤不变式）。 */
    private static void assertNoBotRecipients(List<TableOutbound> out) {
        for (TableOutbound o : out) {
            assertFalse(o.to().startsWith(Table.BOT_ID_PREFIX), "bot 不得收信: " + o.to());
        }
    }

    // ---------------------------------------------------------------- 规则版本（M4）

    @Test
    void M4房主改规则后旧版本准备被拒STALE_RULES并补发tableState() {
        Table t = make();
        fill(t, 3);
        int stale = t.rulesVersion();
        t.updateRules("a", OTHER_RULES, 0);
        assertEquals(stale + 1, t.rulesVersion());
        assertEquals(stale + 1, t.view().rulesVersion());

        List<TableOutbound> out = t.setReady("b", true, stale, 0);
        assertEquals(List.of("b", "b"), tos(out));
        assertEquals(GameErrorCode.STALE_RULES, errorOf(out));
        // 补发本人的 tableState，带上新的规则与 rulesVersion
        assertEquals(new TableOutbound("b", new TableEvent.TableState(t.view())), out.get(1));
        assertFalse(t.view().seats().get(1).ready());
    }

    @Test
    void M4带当前rulesVersion的准备正常生效() {
        Table t = make();
        fill(t, 2);
        t.updateRules("a", OTHER_RULES, 0);
        List<TableOutbound> out = t.setReady("b", true, t.rulesVersion(), 0);
        assertTrue(out.stream().allMatch(o -> o.event() instanceof TableEvent.TableState));
        assertEquals(List.of("a", "b"), tosSorted(out));
        assertTrue(t.view().seats().get(1).ready());
    }

    // ---------------------------------------------------------------- 房主踢人

    @Test
    void 房主踢未准备者被踢者收kicked其余人tableState中座位空出() {
        Table t = make();
        fill(t, 3);
        List<TableOutbound> out = t.kick("a", "b", 0);
        assertEquals(List.of(new TableOutbound("b", new TableEvent.Kicked(t.roomCode()))),
            out.stream().filter(o -> o.event() instanceof TableEvent.Kicked).toList());
        assertEquals(List.of("a", "c"), t.members());
        assertNull(t.view().seats().get(1));
        List<TableOutbound> states = statesOf(out);
        assertEquals(List.of("a", "c"), tosSorted(states));
        assertNull(stateOf(states.get(0)).seats().get(1));
        // 房主仍是 a：房主没被踢，不需要转移
        assertEquals("a", t.view().hostId());
    }

    @Test
    void 评审焦点3目标已准备TARGET_READY座位不变() {
        Table t = make();
        fill(t, 3);
        t.setReady("b", true, t.rulesVersion(), 0);
        List<TableOutbound> out = t.kick("a", "b", 0);
        assertEquals(1, out.size());
        assertEquals("a", out.get(0).to());
        assertEquals(GameErrorCode.TARGET_READY, errorOf(out));
        assertEquals(List.of("a", "b", "c"), t.members());
        assertTrue(t.view().seats().get(1).ready());
        assertNull(t.canJoin("b"));
    }

    @Test
    void 评审焦点3最后一人准备同步开局后再踢ROOM_IN_GAME() {
        // TS 原文 make({capacity: 2})：好友房 2 座，双方 ready 即同步开局
        Table t = new Table(new Table.Options("123456", GameTypes.TableKind.FRIEND, 2, RULES, 0, false, null, null, RNG, null));
        for (String id : IDS.subList(0, 2)) t.join(id, id.toUpperCase(), 0);
        t.setReady("b", true, t.rulesVersion(), 0);
        t.setReady("a", true, t.rulesVersion(), 0);
        assertEquals(GameTypes.TablePhase.IN_GAME, t.phase());
        List<TableOutbound> out = t.kick("a", "b", 0);
        assertEquals(1, out.size());
        assertEquals("a", out.get(0).to());
        assertEquals(GameErrorCode.ROOM_IN_GAME, errorOf(out));
        assertEquals(List.of("a", "b"), t.members());
    }

    @Test
    void 评审焦点3被踢者再join返回BANNEDcanJoin也返回BANNED() {
        Table t = make();
        fill(t, 3);
        t.kick("a", "b", 0);
        assertEquals(GameErrorCode.BANNED, t.canJoin("b"));
        List<TableOutbound> out = t.join("b", "B", 0);
        assertEquals(1, out.size());
        assertEquals("b", out.get(0).to());
        assertEquals(GameErrorCode.BANNED, errorOf(out));
        assertEquals(List.of("a", "c"), t.members());
        // 没被踢的人照常可以加入
        assertNull(t.canJoin("a"));
    }

    @Test
    void 可以踢掉线中的未准备者() {
        Table t = make();
        fill(t, 3);
        t.setConnected("b", false, 100);
        assertFalse(t.view().seats().get(1).connected());
        List<TableOutbound> out = t.kick("a", "b", 200);
        assertTrue(out.stream().anyMatch(o -> o.to().equals("b") && o.event() instanceof TableEvent.Kicked));
        assertEquals(List.of("a", "c"), t.members());
        // 座位已释放，之后不会再被判为掉线超时
        t.tick(100 + Table.MATCH_SEAT_GRACE_MS);
        assertEquals(List.of("a", "c"), t.members());
    }

    @Test
    void 非房主匹配房练习房踢人都返回NOT_HOST() {
        Table t = make();
        fill(t, 3);
        List<TableOutbound> out = t.kick("b", "c", 0);
        assertEquals(1, out.size());
        assertEquals("b", out.get(0).to());
        assertEquals(GameErrorCode.NOT_HOST, errorOf(out));
        assertEquals(List.of("a", "b", "c"), t.members());

        Table m = make("123456", GameTypes.TableKind.MATCH, 3, 0, false, null, null);
        m.join("a", "A", 0);
        m.join("b", "B", 0);
        assertEquals(GameErrorCode.NOT_HOST, errorOf(m.kick("a", "b", 0)));
        assertEquals(List.of("a", "b"), m.members());

        // 练习房没有房主：连"房主"都无从谈起，一律 NOT_HOST
        Table p = make("123456", GameTypes.TableKind.PRACTICE, 3, 0, false, botFactory("123456"), null);
        p.join("human", "我", 0);
        p.addBot(Ruleset.PresetId.BEGINNER, 0);
        String botId = "bot:123456:1:1";
        assertEquals(GameErrorCode.NOT_HOST, errorOf(p.kick("human", botId, 0)));
        assertEquals(List.of("human", botId), p.members());
    }

    @Test
    void 发起者不在桌上返回NOT_IN_ROOM() {
        Table t = make();
        fill(t, 3);
        List<TableOutbound> out = t.kick("x", "b", 0);
        assertEquals(1, out.size());
        assertEquals("x", out.get(0).to());
        assertEquals(GameErrorCode.NOT_IN_ROOM, errorOf(out));
        assertEquals(List.of("a", "b", "c"), t.members());
    }

    @Test
    void 踢自己踢不在桌的人踢电脑都返回TARGET_NOT_FOUND() {
        Table t = make(botFactory("123456"));
        fill(t, 3);
        assertEquals(GameErrorCode.TARGET_NOT_FOUND, errorOf(t.kick("a", "a", 0)));
        assertEquals(GameErrorCode.TARGET_NOT_FOUND, errorOf(t.kick("a", "zzz", 0)));
        t.addBot(Ruleset.PresetId.BEGINNER, 0);
        String botId = "bot:123456:3:1";
        assertTrue(t.members().contains(botId));
        List<TableOutbound> out = t.kick("a", botId, 0);
        assertEquals(1, out.size());
        assertEquals("a", out.get(0).to());
        assertEquals(GameErrorCode.TARGET_NOT_FOUND, errorOf(out));
        assertTrue(t.members().contains(botId));
    }

    @Test
    void kicked只发给被踢者且排在释放之后的tableState不发给被踢者() {
        Table t = make();
        fill(t, 3);
        List<TableOutbound> out = t.kick("a", "c", 0);
        List<TableOutbound> toKicked = out.stream().filter(o -> o.to().equals("c")).toList();
        assertEquals(List.of("kicked"), toKicked.stream().map(o -> o.event() instanceof TableEvent.Kicked ? "kicked" : "?").toList());
        assertEquals(List.of("a", "b"), tosSorted(statesOf(out)));
        // 顺序：先 kicked，再借 release 广播 tableState
        int kickedAt = -1, stateAt = Integer.MAX_VALUE;
        for (int i = 0; i < out.size(); i++) {
            TableEvent e = out.get(i).event();
            if (e instanceof TableEvent.Kicked && kickedAt < 0) kickedAt = i;
            if (e instanceof TableEvent.TableState) stateAt = Math.min(stateAt, i);
        }
        assertEquals(0, kickedAt);
        assertTrue(stateAt > kickedAt);
    }

    // ---------------------------------------------------------------- 大厅列表投影

    @Test
    void 公开等候中有空座的好友房列表条目字段正确() {
        Table t = listedRoom("123456", GameTypes.TableKind.FRIEND, 4, 4242, true);
        fillListed(t, 2);
        assertEquals("abcd1234abcd1234", t.tableId());
        GameTypes.RoomListEntry e = t.listing();
        assertNotNull(e);
        assertEquals(new GameTypes.RoomListEntry("abcd1234abcd1234", 4, RULES, "昵称a", 2,
            java.util.Arrays.asList(new GameTypes.RoomListEntry.PublicSeat(0, "昵称a"),
                    new GameTypes.RoomListEntry.PublicSeat(1, "昵称b"),
                    null, null), 4242), e);
    }

    @Test
    void 电脑座位与真人一样只露出seat与nickname() {
        Table t = make("123456", GameTypes.TableKind.FRIEND, 4, 1000, true,
            botFactory("123456"), "abcd1234abcd1234");
        t.join("a", "昵称a", 1000);
        t.addBot(Ruleset.PresetId.BEGINNER, 1000);
        GameTypes.RoomListEntry entry = t.listing();
        assertNotNull(entry);
        assertEquals(2, entry.seated());
        assertEquals(new GameTypes.RoomListEntry.PublicSeat(1, "电脑2"), entry.seats().get(1));
    }

    @Test
    void 评审焦点5不可列出的六种情形全部返回null() {
        Table match = listedRoom("123456", GameTypes.TableKind.MATCH, 3, 1000, true);
        match.join("a", "A", 1000);
        assertNull(match.listing());
        assertFalse(match.listed());

        Table practice = listedRoom("123456", GameTypes.TableKind.PRACTICE, 3, 1000, true);
        practice.join("a", "A", 1000);
        assertNull(practice.listing());

        Table unlisted = make();
        fill(unlisted, 2);
        assertNull(unlisted.listing());

        Table full = listedRoom("123456", GameTypes.TableKind.FRIEND, 4, 1000, true);
        fill(full, 4);
        assertNull(full.listing());

        Table inGame = listedRoom("123456", GameTypes.TableKind.FRIEND, 2, 1000, true);
        fillListed(inGame, 2);
        inGame.setReady("a", true, inGame.rulesVersion(), 1000);
        inGame.setReady("b", true, inGame.rulesVersion(), 1000);
        assertEquals(GameTypes.TablePhase.IN_GAME, inGame.phase());
        assertNull(inGame.listing());

        Table closed = listedRoom("123456", GameTypes.TableKind.FRIEND, 4, 1000, true);
        fillListed(closed, 1);
        closed.leave("a", 1000);
        assertTrue(closed.closed());
        assertNull(closed.listing());
    }

    @Test
    void 不再满足条件的桌子返回null重新满足后恢复() {
        Table t = listedRoom("123456", GameTypes.TableKind.FRIEND, 2, 1000, true);
        fillListed(t, 1);
        assertNotNull(t.listing());
        t.join("b", "B", 1000);
        assertNull(t.listing());
        t.leave("b", 1000);
        GameTypes.RoomListEntry e = t.listing();
        assertNotNull(e);
        assertEquals(1, e.seated());
    }

    @Test
    void 评审焦点5条目JSON不含roomCode与任何playerId() {
        // 用不会与昵称混淆的 id：昵称里不含 id，断言才只检验"id 是否泄漏"
        Table t = make(listedRoom("123456", GameTypes.TableKind.FRIEND, 4, 1000, true).roomCode(),
            GameTypes.TableKind.FRIEND, 4, 1000, true, botFactory("123456"), "abcd1234abcd1234");
        t.join("pid-alpha", "红方", 1000);
        t.join("pid-beta", "蓝方", 1000);
        t.addBot(Ruleset.PresetId.BEGINNER, 1000);
        String json = String.join("|",
            t.listing().tableId(), String.valueOf(t.listing().capacity()), String.valueOf(t.listing().rules()),
            t.listing().hostNickname(), String.valueOf(t.listing().seated()),
            t.listing().seats().toString(), String.valueOf(t.listing().createdAt()));
        assertFalse(json.contains(t.roomCode()));
        for (String id : t.members()) assertFalse(json.contains(id), "泄漏 playerId: " + id);
        assertFalse(json.contains("bot"));
        assertFalse(json.contains("ready"));
    }

    @Test
    void 房主转移后hostNickname随之改变() {
        Table t = listedRoom("123456", GameTypes.TableKind.FRIEND, 4, 1000, true);
        fillListed(t, 3);
        assertEquals("昵称a", t.listing().hostNickname());
        t.leave("a", 1000);
        assertEquals("昵称b", t.listing().hostNickname());
    }

    @Test
    void 每张桌的tableId默认各不相同且是16位十六进制() {
        Table a = new Table(new Table.Options("111111", GameTypes.TableKind.FRIEND, 2, RULES, 0));
        Table b = new Table(new Table.Options("222222", GameTypes.TableKind.FRIEND, 2, RULES, 0));
        assertTrue(a.tableId().matches("^[0-9a-f]{16}$"), a.tableId());
        assertTrue(b.tableId().matches("^[0-9a-f]{16}$"), b.tableId());
        assertNotEquals(a.tableId(), b.tableId());
    }

    // ---------------------------------------------------------------- setListed

    @Test
    void 房主开启公开广播tableState且listing非空() {
        Table t = listedRoom("123456", GameTypes.TableKind.FRIEND, 4, 1000, false);
        fillListed(t, 2);
        List<TableOutbound> out = t.setListed("a", true);
        assertTrue(t.listed());
        assertTrue(t.view().listed());
        assertTrue(out.stream().allMatch(o -> o.event() instanceof TableEvent.TableState));
        assertEquals(List.of("a", "b"), tosSorted(out));
        assertNotNull(t.listing());
    }

    @Test
    void 非房主setListed返回NOT_HOST状态不变() {
        Table t = listedRoom("123456", GameTypes.TableKind.FRIEND, 4, 1000, false);
        fillListed(t, 2);
        List<TableOutbound> out = t.setListed("b", true);
        assertEquals(GameErrorCode.NOT_HOST, errorOf(out));
        assertFalse(t.listed());
    }

    @Test
    void 不在房间的人setListed返回NOT_IN_ROOM() {
        Table t = listedRoom("123456", GameTypes.TableKind.FRIEND, 4, 1000, false);
        fillListed(t, 1);
        assertEquals(GameErrorCode.NOT_IN_ROOM, errorOf(t.setListed("zzz", true)));
    }

    @Test
    void 匹配房与练习房setListed返回NOT_HOST() {
        Table m = listedRoom("123456", GameTypes.TableKind.MATCH, 3, 1000, false);
        m.join("a", "A", 1000);
        assertEquals(GameErrorCode.NOT_HOST, errorOf(m.setListed("a", true)));
        assertFalse(m.listed());
        Table p = listedRoom("123456", GameTypes.TableKind.PRACTICE, 3, 1000, false);
        p.join("a", "A", 1000);
        assertEquals(GameErrorCode.NOT_HOST, errorOf(p.setListed("a", true)));
    }

    @Test
    void 对局中setListed返回ROOM_IN_GAME() {
        Table t = listedRoom("123456", GameTypes.TableKind.FRIEND, 2, 1000, false);
        fillListed(t, 2);
        t.setReady("a", true, t.rulesVersion(), 1000);
        t.setReady("b", true, t.rulesVersion(), 1000);
        assertEquals(GameErrorCode.ROOM_IN_GAME, errorOf(t.setListed("a", true)));
        assertFalse(t.listed());
    }

    @Test
    void 房主关闭公开后listing为null视图同步() {
        Table t = listedRoom("123456", GameTypes.TableKind.FRIEND, 4, 1000, true);
        fillListed(t, 2);
        assertNotNull(t.listing());
        List<TableOutbound> out = t.setListed("a", false);
        assertTrue(out.stream().allMatch(o -> o.event() instanceof TableEvent.TableState));
        assertNull(t.listing());
        assertFalse(t.view().listed());
    }

    // ---------------------------------------------------------------- bot 桌边界（spec §2 / table.ts:439）

    @Test
    void 发给电脑的所有出站消息在桌边界被丢弃() {
        Table t = make("123456", GameTypes.TableKind.PRACTICE, 2, 0, false, botFactory("123456"), null);
        t.join("a", "A", 0);
        List<TableOutbound> out = t.addBot(Ruleset.PresetId.BEGINNER, 0); // practice 首局人满自动开局
        assertNoBotRecipients(out);
        // 开局广播：真人收到 tableState + state，电脑那一份被滤掉
        assertEquals(List.of("a", "a"), tos(out));
        assertTrue(t.members().get(1).startsWith(Table.BOT_ID_PREFIX));
        t.setConnected("bot:123456:1:1", false, 10); // 电脑恒在线：桌子忽略
        assertTrue(t.view().seats().get(1).connected());
        assertNoBotRecipients(t.tick(60_000));
    }

    @Test
    void tick按座位顺序轮询电脑并把其命令回喂引擎() {
        Table t = make("123456", GameTypes.TableKind.PRACTICE, 3, 0, false,
            (difficulty, seat) -> placingBot("bot:123456:" + seat + ":1", 3, 8), null);
        t.join("a", "A", 0);
        t.join("b", "B", 0);
        t.addBot(Ruleset.PresetId.BEGINNER, 0); // 坐满 → 自动开局
        // 摆放阶段第一 tick：bot 的 poll 摆放 → planeAccepted（发给 bot，桌边界滤掉）
        List<TableOutbound> first = t.tick(1_000);
        assertNoBotRecipients(first);
        // 人类摆放（互不重叠的合法格）：最后一人摆完 → 引擎同步开局，phaseChanged 经桌子透出
        List<TableOutbound> placeA = t.handleGame("a", new Engine.GameCommand.Place(List.of(new Rules.Cell(2, 2), new Rules.Cell(2, 9))), 1_000);
        assertNoBotRecipients(placeA);
        List<TableOutbound> placeB = t.handleGame("b", new Engine.GameCommand.Place(List.of(new Rules.Cell(8, 5), new Rules.Cell(8, 9))), 1_000);
        assertNoBotRecipients(placeB);
        assertTrue(placeB.stream().anyMatch(o -> o.event() instanceof TableEvent.FromEngine fe
            && fe.event() instanceof EngineEvent.PhaseChanged));
        // tick：bot 的 poll 决定行动 → 命令回喂引擎，submitted 广播给人类（bot 那份桌边界滤掉）
        List<TableOutbound> fired = t.tick(1_001);
        assertNoBotRecipients(fired);
        assertTrue(fired.stream().anyMatch(o -> o.to().equals("a") && o.event() instanceof TableEvent.FromEngine fe
            && fe.event() instanceof EngineEvent.Submitted s && s.playerId().equals("bot:123456:2:1")));
        // 后续回合照常推进：轮次结算从引擎透出，桌边界始终不向 bot 投递
        assertNoBotRecipients(t.tick(61_000));
    }
}
