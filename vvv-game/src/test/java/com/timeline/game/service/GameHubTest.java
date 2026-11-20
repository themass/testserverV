package com.timeline.game.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.timeline.game.api.GameConnection;
import com.timeline.game.domain.Coins;
import com.timeline.game.domain.Mulberry32;
import com.timeline.game.domain.Rank;
import com.timeline.game.persistence.GameCoinLedgerMapper;
import com.timeline.game.persistence.GameMatchMapper;
import com.timeline.game.persistence.GameMatchPlayerMapper;
import com.timeline.game.persistence.GameProfileMapper;
import com.timeline.game.persistence.GameProgressMapper;
import com.timeline.game.persistence.GameSeasonMapper;
import com.timeline.game.persistence.GameWalletMapper;
import com.timeline.game.protocol.GameEnvelopeCodec;

import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.time.ZoneId;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.Supplier;

import org.apache.ibatis.jdbc.ScriptRunner;
import org.apache.ibatis.mapping.Environment;
import org.apache.ibatis.session.Configuration;
import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactory;
import org.apache.ibatis.session.SqlSessionFactoryBuilder;
import org.apache.ibatis.transaction.jdbc.JdbcTransactionFactory;
import org.h2.jdbcx.JdbcDataSource;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;

/**
 * GameHub 在 H2（MODE=MySQL）上的行为对拍（TS hub-e2e / hub-lifecycle / hub-p2 / hub-p3 /
 * hub-room-list 五套测试的 Java 移植，建库方式与 GameSettlementServiceTest 同款）。
 *
 * <p>夹具口径：
 * <ul>
 *   <li>假连接 FakeConn 记录每一帧 wire JSON（TS inbox 直译），断言全部走事件名 + data；</li>
 *   <li>假时钟 AtomicLong 起于赛季 1（AT 早于 SEASON_EPOCH_MS），跨季测试再推过季界；</li>
 *   <li>房间号来自确定性队列（碰撞重试用例单独给短队列）；</li>
 *   <li>匹配默认开补位（1ms 即补，perCapacity）；queueTimeout 用例单独建"补位关闭"的 Hub；</li>
 *   <li>身份走握手 onConnect(clientId, conn, userId, name)——TS 的 auth/token 夹具整体不再存在，
 *       但顶号显式 close、旧 socket 断线无害、重连补快照等语义逐一保留。</li>
 * </ul>
 */
class GameHubTest {

    private static final ZoneId ZONE = ZoneId.of("Asia/Shanghai");
    /** 赛季 1 内的固定时刻（与 GameSettlementServiceTest 同基准）。 */
    private static final long AT = 1_795_000_000_000L;
    private static final String RULES =
        "{\"boardSize\":10,\"planeCount\":1,\"turnSeconds\":20,\"hintAllowed\":false}";

    private final ObjectMapper mapper = new ObjectMapper();
    private final AtomicLong clock = new AtomicLong(AT);

    private SqlSession session;
    private GameMatchMapper matchMapper;
    private GameWalletMapper walletMapper;
    private GameWalletService wallet;
    private GameProfileService profiles;
    private GameHub hub;
    private final Map<String, FakeConn> conns = new HashMap<>();
    private final Map<String, Long> seqs = new HashMap<>();
    private long fundSeq = 0;

    /** 假连接（TS inbox 直译）：记录每一帧，close() 记标志。 */
    private final class FakeConn implements GameConnection {
        final List<JsonNode> frames = new ArrayList<>();
        boolean closed = false;

        @Override public void send(String json) {
            try { frames.add(mapper.readTree(json)); }
            catch (Exception e) { throw new IllegalStateException(e); }
        }
        @Override public void close() { closed = true; }
    }

    // ================================================================ 装配

    @BeforeEach
    void setUp() throws Exception {
        JdbcDataSource ds = new JdbcDataSource();
        ds.setURL("jdbc:h2:mem:hub_" + System.nanoTime()
            + ";MODE=MySQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1");
        ds.setUser("sa");
        try (Connection c = ds.getConnection(); Reader r = openH2Schema()) {
            ScriptRunner runner = new ScriptRunner(c);
            runner.setSendFullScript(false);
            runner.setStopOnError(true);
            runner.setLogWriter(new java.io.PrintWriter(new java.io.Writer() {
                @Override public void write(char[] cbuf, int off, int len) {}
                @Override public void flush() {}
                @Override public void close() {}
            }));
            runner.setErrorLogWriter(null);
            runner.runScript(r);
        }
        Configuration cfg = new Configuration(
            new Environment("h2", new JdbcTransactionFactory(), ds));
        cfg.addMapper(GameProfileMapper.class);
        cfg.addMapper(GameProgressMapper.class);
        cfg.addMapper(GameWalletMapper.class);
        cfg.addMapper(GameCoinLedgerMapper.class);
        cfg.addMapper(GameMatchMapper.class);
        cfg.addMapper(GameMatchPlayerMapper.class);
        cfg.addMapper(GameSeasonMapper.class);
        SqlSessionFactory factory = new SqlSessionFactoryBuilder().build(cfg);
        session = factory.openSession(true);
        matchMapper = session.getMapper(GameMatchMapper.class);
        walletMapper = session.getMapper(GameWalletMapper.class);
        wallet = new GameWalletService(walletMapper, session.getMapper(GameCoinLedgerMapper.class));
        profiles = new GameProfileService(session.getMapper(GameProfileMapper.class),
            session.getMapper(GameProgressMapper.class), walletMapper,
            session.getMapper(GameCoinLedgerMapper.class), matchMapper, null, ZONE);
        // 默认开补位（1ms 即补）；queueTimeout 用例另行建"补位关闭"的 Hub
        hub = makeHub(Matchmaking.perCapacity(null, Map.of(2, 1L, 3, 1L, 4, 1L)),
            cyclingCodes("111111", "222222", "333333", "444444", "555555",
                "666666", "777777", "888888", "999999"), null, null);
    }

    @AfterEach
    void tearDown() {
        if (session != null) session.close();
    }

    private static Reader openH2Schema() {
        InputStream in = GameHubTest.class.getClassLoader()
            .getResourceAsStream("db/game/h2-schema.sql");
        assertNotNull(in, "h2-schema.sql 不在测试 classpath 上");
        return new InputStreamReader(in, StandardCharsets.UTF_8);
    }

    private GameHub makeHub(Matchmaking mm, Supplier<String> codes,
                            GameHub.SeasonResetHook hook, GameHub.TxRunner tx) {
        return new GameHub(mapper, clock::get, ZONE, profiles, wallet,
            new GameSettlementService(matchMapper, session.getMapper(GameMatchPlayerMapper.class),
                session.getMapper(GameProgressMapper.class),
                session.getMapper(GameProfileMapper.class), wallet, ZONE),
            mm, codes, Mulberry32.of(42), hook, tx);
    }

    /** 确定性房间号：按序取，最后一个可重复（给碰撞重试留尾巴；正常用例用不到这么深）。 */
    private static Supplier<String> cyclingCodes(String... codes) {
        Deque<String> deque = new ArrayDeque<>(List.of(codes));
        return () -> deque.size() > 1 ? deque.poll() : deque.peek();
    }

    // ================================================================ 客户端夹具

    /** 握手建连（握手鉴权即认证；TS open+auth 的替代）。 */
    private FakeConn connect(String clientId, long userId, String name) {
        FakeConn conn = new FakeConn();
        conns.put(clientId, conn);
        hub.onConnect(clientId, conn, userId, name);
        return conn;
    }

    private void send(String clientId, String cmd, String dataJson) {
        long seq = seqs.merge(clientId, 1L, Long::sum);
        ObjectNode env = mapper.createObjectNode();
        env.put("v", 1);
        env.put("cmd", cmd);
        env.put("seq", seq);
        try {
            env.set("data", dataJson == null || dataJson.isEmpty()
                ? mapper.createObjectNode() : mapper.readTree(dataJson));
        } catch (Exception e) { throw new IllegalStateException(e); }
        GameEnvelopeCodec.DecodeResult d = GameEnvelopeCodec.decode(mapper, env.toString());
        assertTrue(d.ok(), "测试信封必须可解码: " + cmd);
        hub.onCommand(clientId, d.inbound());
    }

    private void advance(long ms) {
        clock.addAndGet(ms);
        hub.tick(clock.get());
    }

    private List<JsonNode> frames(String clientId, String evt) {
        FakeConn conn = conns.get(clientId);
        if (conn == null) return List.of();
        return conn.frames.stream().filter(f -> evt.equals(f.path("evt").asText())).toList();
    }

    private JsonNode last(String clientId, String evt) {
        List<JsonNode> fs = frames(clientId, evt);
        return fs.isEmpty() ? null : fs.get(fs.size() - 1);
    }

    private int count(String clientId, String evt) { return frames(clientId, evt).size(); }

    /**
     * 最近一次 table.state 里的桌子视图。两种形态都要吃下：
     * 广播的 table.state data 直接就是桌子视图；私有快照 data = {table, game}。
     */
    private JsonNode tableOf(String clientId) {
        JsonNode f = last(clientId, "table.state");
        if (f == null) return mapper.createObjectNode();
        JsonNode data = f.path("data");
        return data.has("table") ? data.path("table") : data;
    }

    private String roomCodeOf(String clientId) { return tableOf(clientId).path("roomCode").asText(); }

    /** 帧里的桌子视图：广播形态 data=桌子视图；私有快照形态 data={table, game}。 */
    private static JsonNode tableViewOf(JsonNode frame) {
        JsonNode data = frame.path("data");
        return data.has("table") ? data.path("table") : data;
    }

    /** 在座真人数（seats 数组含 null 空位，不能直接 size()）。 */
    private int seatedCount(String clientId) {
        int n = 0;
        for (JsonNode s : tableOf(clientId).path("seats")) if (!s.isNull()) n++;
        return n;
    }

    /** 最近一帧 error 的 code；没有 error 帧返回 null。 */
    private String lastErrorCode(String clientId) {
        List<JsonNode> errs = frames(clientId, "error");
        return errs.isEmpty() ? null : errs.get(errs.size() - 1).path("data").path("code").asText();
    }

    private void assertError(String clientId, String code) { assertEquals(code, lastErrorCode(clientId)); }

    /** duel 当前开炮者：摆放完成时 phase.changed 带 turn（wire 口径，不碰内部引擎）。 */
    private String turnOf(String clientId) {
        JsonNode f = last(clientId, "phase.changed");
        assertNotNull(f, "应有 phase.changed 事件");
        String turn = f.path("data").path("turn").asText(null);
        assertNotNull(turn, "duel 的 phase.changed 必须带 turn");
        return turn;
    }

    private void createRoom(String sid, int capacity, boolean listed) {
        send(sid, "room.create",
            "{\"capacity\":" + capacity + ",\"listed\":" + listed + ",\"rules\":" + RULES + "}");
    }

    private void ready(String sid) {
        send(sid, "room.ready", "{\"ready\":true,\"rulesVersion\":"
            + tableOf(sid).path("rulesVersion").asInt() + "}");
    }

    /** 两人好友房摆好进入 duel（TS startDuel 直译：机头 2,2 对 7,7）。 */
    private void startDuel(String sidA, String sidB) {
        createRoom(sidA, 2, false);
        send(sidB, "room.join", "{\"roomCode\":\"" + roomCodeOf(sidA) + "\"}");
        ready(sidA);
        ready(sidB);
        send(sidA, "game.place", "{\"planes\":[{\"row\":2,\"col\":2}]}");
        send(sidB, "game.place", "{\"planes\":[{\"row\":7,\"col\":7}]}");
    }

    /** 轮到谁谁打掉对方机头，对局即结束（TS finishDuel）。 */
    private void finishDuel(String sidA, String sidB) {
        String turn = turnOf(sidA);
        String sid = sidA.equals(turn) ? sidA : sidB;
        int[] head = sidA.equals(turn) ? new int[]{7, 7} : new int[]{2, 2};
        send(sid, "game.fire", "{\"row\":" + head[0] + ",\"col\":" + head[1] + "}");
    }

    /**
     * 余额注入（TS 直发金币的替代：GAME 账目带唯一 id，不触日上限与幂等）。
     * 先走一次 profile() 建档——生产路径上握手/HTTP 首屏总是先建 profile 行；
     * 若让 grant 先单独建钱包，profile() 首见建档的 insertInitial 会撞主键。
     */
    private void fund(long userId, int amount) {
        profiles.profile(userId, null, clock.get());
        wallet.grant(userId, new Coins.CoinOp(Coins.CoinReason.GAME,
            "fund:" + (++fundSeq), String.valueOf(userId), clock.get(), amount), ZONE);
    }

    private int balance(long userId) {
        return profiles.profile(userId, null, clock.get()).coins().balance();
    }

    private int matchRowCount() throws Exception {
        try (var st = session.getConnection().createStatement();
             var rs = st.executeQuery("SELECT COUNT(*) FROM game_match")) {
            rs.next();
            return rs.getInt(1);
        }
    }

    /** 桌已随结算关闭时，从流水 game 账目反推 gameId（幂等键 game:{gameId}:{uid}）。 */
    private String gameIdFromLedger(long uid) {
        for (var e : profiles.coinsLedger(uid).entries()) {
            if ("game".equals(e.reason())) {
                String key = e.entryKey();
                // 去头 game: 去尾 :uid，剩下就是 gameId（本身可含冒号：{tableId}:{n}）。
                return key.substring("game:".length(), key.lastIndexOf(':'));
            }
        }
        throw new AssertionError("流水里没有 game 账目");
    }

    // ================================================================ 好友房（hub-e2e）

    @Test
    void 建二人好友房加入准备后进入duel并收到私有快照() {
        connect("s1", 10, "小明");
        connect("s2", 20, "小红");
        createRoom("s1", 2, false);
        assertEquals("waiting", tableOf("s1").path("phase").asText());
        send("s2", "room.join", "{\"roomCode\":\"" + roomCodeOf("s1") + "\"}");
        assertEquals("20", tableOf("s2").path("seats").get(1).path("playerId").asText());
        ready("s1");
        ready("s2");
        // 双方进入摆放：全员各收到一条带 game 节点的私有快照（broadcastStart 的 state 半边）
        assertEquals("in_game", tableOf("s1").path("phase").asText());
        JsonNode snap = last("s2", "table.state").path("data");
        assertTrue(snap.has("game"));
        assertEquals("duel", snap.path("game").path("mode").asText());
        assertNotNull(snap.path("game").path("deadlineAt"));
        assertEquals("10", tableOf("s2").path("hostId").asText()); // 好友房有房主
    }

    @Test
    void 加入不存在的房间返回ROOM_NOT_FOUND() {
        connect("s1", 10, null);
        send("s1", "room.join", "{\"roomCode\":\"999999\"}");
        assertError("s1", "ROOM_NOT_FOUND");
    }

    @Test
    void 第三人加入已满房间被拒且不离开自己原来的桌() {
        connect("s1", 10, null);
        connect("s2", 20, null);
        connect("s3", 30, null);
        createRoom("s1", 2, false);
        String a = roomCodeOf("s1");
        send("s2", "room.join", "{\"roomCode\":\"" + a + "\"}");
        createRoom("s3", 2, false);
        String own = roomCodeOf("s3");
        send("s3", "room.join", "{\"roomCode\":\"" + a + "\"}");
        assertError("s3", "ROOM_FULL");
        // RF#5：目标进不去，人不能先被赶走
        assertEquals(own, hub.peekRoomOf("30"));
        assertEquals(1, seatedCount("s3"));
    }

    @Test
    void 房间号生成器碰撞时重试() {
        hub = makeHub(new Matchmaking(), cyclingCodes("111111", "111111", "222222"), null, null);
        connect("s1", 10, null);
        connect("s2", 20, null);
        createRoom("s1", 2, false);
        assertEquals("111111", roomCodeOf("s1"));
        createRoom("s2", 2, false);
        assertEquals("222222", roomCodeOf("s2"));  // 第二次先撞 111111 再重试
    }

    @Test
    void 重复加入自己所在的桌只补发快照不让位() {
        connect("s1", 10, null);
        connect("s2", 20, null);
        createRoom("s1", 2, false);
        String code = roomCodeOf("s1");
        send("s2", "room.join", "{\"roomCode\":\"" + code + "\"}");
        int states1 = count("s1", "table.state");
        int states2 = count("s2", "table.state");
        send("s2", "room.join", "{\"roomCode\":\"" + code + "\"}");
        assertEquals(states2 + 1, count("s2", "table.state")); // 本人补一条快照
        assertEquals(states1, count("s1", "table.state"));     // 老成员不被广播
        assertEquals("10", tableOf("s2").path("hostId").asText()); // 房主不因自己让位
    }

    @Test
    void 房主改规则后同桌看到新版本非房主改规则被拒() {
        connect("s1", 10, null);
        connect("s2", 20, null);
        createRoom("s1", 2, false);
        send("s2", "room.join", "{\"roomCode\":\"" + roomCodeOf("s1") + "\"}");
        send("s2", "room.rules", "{\"rules\":{\"boardSize\":12,\"planeCount\":2,"
            + "\"turnSeconds\":20,\"hintAllowed\":false}}");
        assertError("s2", "NOT_HOST");
        send("s1", "room.rules", "{\"rules\":{\"boardSize\":12,\"planeCount\":2,"
            + "\"turnSeconds\":20,\"hintAllowed\":false}}");
        assertEquals(1, tableOf("s2").path("rulesVersion").asInt());
        assertEquals(12, tableOf("s2").path("rules").path("boardSize").asInt());
    }

    @Test
    void 协议v3旧规则版本ready回STALE_RULES并补发当前桌子() {
        connect("s1", 10, null);
        connect("s2", 20, null);
        createRoom("s1", 2, false);
        send("s2", "room.join", "{\"roomCode\":\"" + roomCodeOf("s1") + "\"}");
        send("s1", "room.rules", "{\"rules\":{\"boardSize\":12,\"planeCount\":2,"
            + "\"turnSeconds\":20,\"hintAllowed\":false}}");
        int states = count("s2", "table.state");
        send("s2", "room.ready", "{\"ready\":true,\"rulesVersion\":0}");
        assertError("s2", "STALE_RULES");
        assertEquals(states + 1, count("s2", "table.state")); // STALE_RULES 附带的私有 tableState
    }

    // ================================================================ 换桌 / 对局中拒绝（RF#4/§4）

    @Test
    void 等候时建房自动离开旧桌() {
        connect("s1", 10, null);
        connect("s2", 20, null);
        createRoom("s1", 2, false);
        String a = roomCodeOf("s1");
        send("s2", "room.join", "{\"roomCode\":\"" + a + "\"}");
        createRoom("s2", 2, false);      // 建房走 leaveCurrent：自动离开 A
        assertEquals(roomCodeOf("s2"), hub.peekRoomOf("20"));
        assertEquals(1, seatedCount("s1")); // A 桌座位空出
    }

    @Test
    void 对局中换房或建房被拒ALREADY_IN_ROOM且不被赶走() {
        connect("s1", 10, null);
        connect("s2", 20, null);
        connect("s3", 30, null);
        startDuel("s1", "s2");
        createRoom("s3", 2, false);
        send("s2", "room.join", "{\"roomCode\":\"" + roomCodeOf("s3") + "\"}");
        assertError("s2", "ALREADY_IN_ROOM");
        send("s2", "room.create", "{\"capacity\":2,\"listed\":false,\"rules\":" + RULES + "}");
        assertError("s2", "ALREADY_IN_ROOM");
        assertNotNull(hub.peekRoomOf("20")); // 仍在原桌
    }

    // ================================================================ 重连 / 顶号（hub-lifecycle）

    @Test
    void 同userId新会话顶掉旧会话并显式关闭旧socket旧socket断线无害() {
        FakeConn old = connect("s1", 10, "小明");
        connect("s2", 20, null);
        createRoom("s1", 2, false);
        String code = roomCodeOf("s1");
        send("s2", "room.join", "{\"roomCode\":\"" + code + "\"}");

        FakeConn fresh = new FakeConn();
        conns.put("s1b", fresh);
        hub.onConnect("s1b", fresh, 10, "小明");
        assertTrue(old.closed, "旧连接必须被显式 close");
        // 重连恢复：仍挂在桌上 → presence/广播 + 私有快照（I2）
        assertTrue(frames("s1b", "table.state").size() >= 2);

        int freshStates = count("s1b", "table.state");
        hub.onDisconnect("s1");  // 被顶掉的旧 socket 真正断开
        assertEquals(freshStates, count("s1b", "table.state")); // 不影响新会话
        assertNotNull(hub.peekRoomOf("10"));                    // 座位还在桌上
    }

    @Test
    void 等候室半开连接重连也能拿到state快照() {
        connect("s1", 10, null);
        createRoom("s1", 2, false);
        String code = roomCodeOf("s1");
        connect("s2", 20, null);
        send("s2", "room.join", "{\"roomCode\":\"" + code + "\"}");
        // 没有 disconnect 直接重连（半开）：新会话必须补发快照
        connect("s2b", 20, null);
        JsonNode snap = last("s2b", "table.state").path("data");
        assertTrue(snap.has("table"), "半开重连必须收到私有快照");
        assertEquals(code, snap.path("table").path("roomCode").asText());
        assertTrue(snap.path("game").isNull()); // 等候期 game 为 null
    }

    @Test
    void 重连时握手昵称覆盖座位昵称() {
        connect("s1", 10, "小明");
        connect("s2", 20, "小红");
        createRoom("s1", 2, false);
        send("s2", "room.join", "{\"roomCode\":\"" + roomCodeOf("s1") + "\"}");
        connect("s2b", 20, "大红"); // I7：离线改名不生效，握手昵称为准
        String seat1Nick = null;
        for (JsonNode s : tableOf("s1").path("seats")) {
            if (s.path("seat").asInt() == 1) seat1Nick = s.path("nickname").asText();
        }
        assertEquals("大红", seat1Nick);
    }

    @Test
    void 匹配桌有人离开留守者按gameOver名次tableState再tableClosed顺序收到() throws Exception {
        connect("s1", 10, null);
        connect("s2", 20, null);
        send("s1", "queue.join", "{\"capacity\":2,\"preset\":\"standard\"}");
        send("s2", "queue.join", "{\"capacity\":2,\"preset\":\"standard\"}");
        assertEquals("in_game", tableOf("s1").path("phase").asText()); // 满员组立即建房并自动开局
        send("s1", "game.place", "{\"planes\":[{\"row\":2,\"col\":2}]}");
        send("s2", "game.place", "{\"planes\":[{\"row\":7,\"col\":7}]}");

        // s2 弃局：duel 判负 → gameOver →（结算）→ tableState(带 lastResult) → table.closed
        send("s2", "room.leave", "{}");

        List<String> evts = conns.get("s1").frames.stream().map(f -> f.path("evt").asText()).toList();
        int over = evts.lastIndexOf("game.over");
        int lastResult = -1;
        for (int i = 0; i < conns.get("s1").frames.size(); i++) {
            JsonNode f = conns.get("s1").frames.get(i);
            if ("table.state".equals(f.path("evt").asText())
                && !tableViewOf(f).path("lastResult").isNull()) lastResult = i;
        }
        int closedIdx = evts.lastIndexOf("table.closed");
        assertTrue(over >= 0, "留守者要看到 game.over");
        assertTrue(lastResult > over, "game.over 必须先于带名次的 tableState（评审 C1）");
        assertTrue(closedIdx > lastResult, "table.closed 必须在名次之后");
        // 中途离开者不参与结算，留下的人照常计分：game 行存在
        assertEquals(1, matchRowCount());
    }

    // ================================================================ 匹配（hub-e2e / hub-p2）

    @Test
    void 四人快配同一张match桌按预设建房自动开局无房主() {
        for (int i = 1; i <= 4; i++) connect("s" + i, 10L * i, null);
        for (int i = 1; i <= 4; i++) {
            send("s" + i, "queue.join", "{\"capacity\":4,\"preset\":\"standard\"}");
        }
        for (int i = 1; i <= 4; i++) {
            JsonNode t = tableOf("s" + i);
            assertEquals("match", t.path("kind").asText());
            assertEquals("in_game", t.path("phase").asText());   // 满员首局自动开局
            assertTrue(t.path("hostId").isNull());              // 匹配桌没有房主
            assertEquals(10, t.path("rules").path("boardSize").asInt()); // PRESETS.standard
            assertEquals(20, t.path("rules").path("turnSeconds").asInt());
        }
        assertEquals(roomCodeOf("s1"), roomCodeOf("s4"));
    }

    @Test
    void 不同档位队列互不凑对() {
        connect("s1", 10, null);
        connect("s2", 20, null);
        connect("s3", 30, null);
        send("s1", "queue.join", "{\"capacity\":2,\"preset\":\"beginner\"}");
        send("s2", "queue.join", "{\"capacity\":2,\"preset\":\"beginner\"}");
        send("s3", "queue.join", "{\"capacity\":2,\"preset\":\"standard\"}");
        advance(2);
        assertNull(hub.peekRoomOf("30"));          // 档位隔离：standard 单人不成桌
        assertEquals("in_game", tableOf("s1").path("phase").asText());
    }

    @Test
    void 排队时加入好友房自动出队此后不再被补位成桌() {
        connect("s1", 10, null);
        connect("s2", 20, null);
        send("s1", "queue.join", "{\"capacity\":2,\"preset\":\"standard\"}");
        createRoom("s2", 2, false);
        send("s1", "room.join", "{\"roomCode\":\"" + roomCodeOf("s2") + "\"}");
        // RF#4：出队彻底——推进补位倒计时也不给他建第二张桌
        advance(5_000);
        assertEquals(2, seatedCount("s1")); // 仍在 s2 的好友房
        assertTrue(frames("s1", "table.state").stream()
            .allMatch(f -> "friend".equals(tableViewOf(f).path("kind").asText())));
    }

    @Test
    void 排队者断线即出队队友收到人数重发() {
        connect("s1", 10, null);
        connect("s2", 20, null);
        send("s1", "queue.join", "{\"capacity\":3,\"preset\":\"standard\"}");
        send("s2", "queue.join", "{\"capacity\":3,\"preset\":\"standard\"}");
        hub.onDisconnect("s1");
        JsonNode st = last("s2", "queue.status");
        assertEquals(1, st.path("data").path("waiting").asInt());
        assertEquals(1, st.path("data").path("humansNeeded").asInt());
    }

    @Test
    void queueLeave出队重发人数重复退队NOT_IN_QUEUE() {
        connect("s1", 10, null);
        connect("s2", 20, null);
        send("s1", "queue.join", "{\"capacity\":3,\"preset\":\"standard\"}");
        send("s2", "queue.join", "{\"capacity\":3,\"preset\":\"standard\"}");
        send("s1", "queue.leave", "{}");
        assertEquals(1, last("s2", "queue.status").path("data").path("waiting").asInt());
        send("s1", "queue.leave", "{}");
        assertError("s1", "NOT_IN_QUEUE");
    }

    @Test
    void 补位关闭时等待60秒只提示一次queueTimeout() {
        hub = makeHub(new Matchmaking(), cyclingCodes("111111", "222222"), null, null);
        connect("s1", 10, null);
        send("s1", "queue.join", "{\"capacity\":2,\"preset\":\"standard\"}");
        advance(30_000);
        assertEquals(0, count("s1", "queue.timeout"));
        advance(30_000);
        assertEquals(1, count("s1", "queue.timeout"));
        advance(60_000);
        assertEquals(1, count("s1", "queue.timeout"));  // 一次性提示
        assertNull(hub.peekRoomOf("10"));               // 单人绝不补位成桌
    }

    @Test
    void 补位开启两人排三人桌到点成match桌空位是电脑按预设开局() {
        connect("s1", 10, null);
        connect("s2", 20, null);
        send("s1", "queue.join", "{\"capacity\":3,\"preset\":\"standard\"}");
        send("s2", "queue.join", "{\"capacity\":3,\"preset\":\"standard\"}");
        advance(2);
        JsonNode t = tableOf("s1");
        assertEquals("match", t.path("kind").asText());
        assertEquals("in_game", t.path("phase").asText());
        int bots = 0;
        for (JsonNode s : t.path("seats")) if (s.path("bot").asBoolean()) bots++;
        assertEquals(1, bots);
        assertEquals(10, t.path("rules").path("boardSize").asInt()); // PRESETS.standard
    }

    @Test
    void 单人排四人桌等120秒也不建桌() {
        connect("s1", 10, null);
        send("s1", "queue.join", "{\"capacity\":4,\"preset\":\"standard\"}");
        advance(120_000);
        assertNull(hub.peekRoomOf("10"));
    }

    // ================================================================ 练习桌（hub-p2）

    @Test
    void 练习桌自动补电脑座位无房主不可按房间号加入离开即关桌() {
        connect("s1", 10, null);
        connect("s2", 20, null);
        send("s1", "practice.create", "{\"preset\":\"standard\",\"capacity\":3}");
        String code = roomCodeOf("s1");
        JsonNode t = tableOf("s1");
        assertEquals("practice", t.path("kind").asText());
        assertTrue(t.path("hostId").isNull());
        int bots = 0;
        for (JsonNode s : t.path("seats")) if (s.path("bot").asBoolean()) bots++;
        assertEquals(2, bots);
        send("s2", "room.join", "{\"roomCode\":\"" + code + "\"}");
        assertError("s2", "ROOM_NOT_FOUND"); // 练习桌不可寻址
        send("s1", "room.leave", "{}");
        assertNull(hub.peekRoomOf("10")); // 唯一真人离开：桌子关闭不再空转
    }

    // ================================================================ 踢人（hub-p2）

    @Test
    void 房主踢人被踢者先收kicked后续广播不再投他() {
        connect("s1", 10, null);
        connect("s2", 20, null);
        createRoom("s1", 2, false);
        String code = roomCodeOf("s1");
        send("s2", "room.join", "{\"roomCode\":\"" + code + "\"}");
        int states1 = count("s1", "table.state");
        int states2 = count("s2", "table.state");
        send("s1", "room.kick", "{\"playerId\":\"20\"}");
        JsonNode kicked = last("s2", "table.kicked");
        assertNotNull(kicked);
        assertEquals(code, kicked.path("data").path("roomCode").asText());
        // kicked 之后 s2 只多了这一条：释放座位的广播不再投他（RF#3/I4）
        assertEquals(states2, count("s2", "table.state"));
        assertTrue(count("s1", "table.state") > states1);
        assertNull(hub.peekRoomOf("20"));
    }

    @Test
    void 非房主不能踢已准备的客人回TARGET_READY() {
        connect("s1", 10, null);
        connect("s2", 20, null);
        connect("s3", 30, null);
        createRoom("s1", 3, false);
        String code = roomCodeOf("s1");
        send("s2", "room.join", "{\"roomCode\":\"" + code + "\"}");
        send("s3", "room.join", "{\"roomCode\":\"" + code + "\"}");
        send("s2", "room.kick", "{\"playerId\":\"30\"}");
        assertError("s2", "NOT_HOST");     // 房主以外不能踢
        ready("s3");
        send("s1", "room.kick", "{\"playerId\":\"30\"}");
        assertError("s1", "TARGET_READY"); // 已准备的客人不能踢
    }

    @Test
    void 被踢后再用房间号加入被BANNED且不去动他现在所在的桌() {
        connect("s1", 10, null);
        connect("s2", 20, null);
        createRoom("s1", 3, false);
        String code = roomCodeOf("s1");
        send("s2", "room.join", "{\"roomCode\":\"" + code + "\"}");
        send("s1", "room.kick", "{\"playerId\":\"20\"}");
        createRoom("s2", 2, false);
        String own = roomCodeOf("s2");
        send("s2", "room.join", "{\"roomCode\":\"" + code + "\"}");
        assertError("s2", "BANNED");
        assertEquals(own, hub.peekRoomOf("20")); // 被拒不影响现桌（RF#5）
    }

    @Test
    void 不在桌上时桌子类命令统一NOT_IN_ROOM道具UNSUPPORTED() {
        connect("s1", 10, null);
        for (String cmd : List.of("room.ready", "room.rules", "room.leave", "game.fire")) {
            send("s1", cmd, "{}");
            assertError("s1", "NOT_IN_ROOM");
        }
        send("s1", "game.item", "{}");
        assertError("s1", "UNSUPPORTED"); // 道具未开放；坏输入保活不断连
    }

    // ================================================================ 公开列表加入（joinListed）

    @Test
    void 按tableId加入未公开桌按不存在处理满座ROOM_FULL() {
        connect("s1", 10, null);
        connect("s2", 20, null);
        connect("s3", 30, null);
        createRoom("s1", 2, false);
        // 未公开：listing() 为空且非"满/局中" → 等同不存在
        send("s2", "room.join", "{\"tableId\":\"nope0000000000000\"}");
        assertError("s2", "ROOM_NOT_FOUND");

        send("s1", "room.listed", "{\"listed\":true}");
        String tableId = hub.peekTable(roomCodeOf("s1")).tableId();
        send("s2", "room.join", "{\"tableId\":\"" + tableId + "\"}");
        assertEquals(roomCodeOf("s1"), hub.peekRoomOf("20"));

        // 满座：第三人被拒且被拒后仍坐在自己的原桌（RF#5）
        createRoom("s3", 2, false);
        String s3own = roomCodeOf("s3");
        send("s3", "room.join", "{\"tableId\":\"" + tableId + "\"}");
        assertError("s3", "ROOM_FULL");
        assertEquals(s3own, hub.peekRoomOf("30"));
    }

    // ================================================================ 大厅列表（hub-room-list）

    @Test
    void 订阅即快照到点合并推送进房自动退订() {
        connect("s1", 10, null);
        connect("s2", 20, null);
        send("s1", "room.list", "{\"subscribe\":true,\"capacity\":2}");
        assertEquals(1, count("s1", "room.list")); // 订阅立即快照（空列表）
        // 同窗口内的变化不推（最小间隔 1s，保持脏待合并）
        createRoom("s2", 2, true);
        hub.tick(clock.get());
        assertEquals(1, count("s1", "room.list"));
        advance(1_000);
        assertEquals(2, count("s1", "room.list"));
        JsonNode data = last("s1", "room.list").path("data");
        assertEquals(2, data.path("capacity").asInt());
        assertEquals(1, data.path("entries").size());
        // 建房 → 大厅不在前台：自动退订；此后再无 room.list
        createRoom("s1", 2, false);
        advance(2_000);
        assertEquals(2, count("s1", "room.list"));
    }

    @Test
    void 列表条目逐字段脱敏在座多者在前内容未变不重推() {
        connect("s1", 10, null);
        connect("s2", 20, null);
        connect("s3", 30, null);
        connect("s4", 40, null);
        createRoom("s3", 3, true);          // 1 人座（333333）
        createRoom("s2", 3, true);          // 1 人座（222222，更新建）
        String bCode = roomCodeOf("s2");
        send("s4", "room.join", "{\"roomCode\":\"" + bCode + "\"}"); // → 2 人座
        send("s1", "room.list", "{\"subscribe\":true,\"capacity\":3}");
        JsonNode entries = last("s1", "room.list").path("data").path("entries");
        assertEquals(2, entries.size());
        // 排序：在座多者在前
        assertEquals(2, entries.get(0).path("seated").asInt());
        assertEquals(1, entries.get(1).path("seated").asInt());
        // 隐私红线（spec §6.8）：条目逐字段拼，不含 roomCode/playerId/ready
        JsonNode e = entries.get(0);
        assertTrue(e.has("tableId") && e.has("capacity") && e.has("hostNickname")
            && e.has("seated") && e.has("seats") && e.has("createdAt"));
        assertFalse(e.has("roomCode"));
        assertFalse(e.has("playerId"));
        assertFalse(e.get("seats").get(0).has("ready"));
        // 内容未变：下个窗口不重推
        int before = count("s1", "room.list");
        advance(2_000);
        assertEquals(before, count("s1", "room.list"));
    }

    // ================================================================ 门票状态机（§廿二.3）

    /**
     * TS hub.ts queueJoin 门票状态机的完整口径（§廿二.3 + 评审 #1）。
     */
    @Test
    void 付费入队扣门票离队全额退同毫秒切档幂等键不互吞() {
        fund(10, 100);
        connect("s1", 10, null);
        send("s1", "queue.join", "{\"capacity\":2,\"preset\":\"standard\",\"ticket\":\"standard\"}");
        assertEquals(50, balance(10));
        assertEquals("ticket-fee", last("s1", "coins.now").path("data").path("reason").asText());
        // 同队重复入队 = no-op：不重扣
        send("s1", "queue.join", "{\"capacity\":2,\"preset\":\"standard\",\"ticket\":\"standard\"}");
        assertEquals(50, balance(10));
        send("s1", "queue.leave", "{}");
        assertEquals(100, balance(10));
        assertEquals("ticket-refund", last("s1", "coins.now").path("data").path("reason").asText());
        // 同毫秒切档：新扣费的幂等键必须带单调 seq（评审 #1），不能被上一笔吞成 applied=0
        send("s1", "queue.join", "{\"capacity\":2,\"preset\":\"standard\",\"ticket\":\"advanced\"}");
        assertEquals(0, balance(10)); // 100 − 100：新扣费真的落了账
        send("s1", "queue.leave", "{}");
        assertEquals(100, balance(10));
    }

    @Test
    void 余额不足支付门票回BALANCE_LOW不入队() {
        connect("s1", 10, null); // 余额 0
        send("s1", "queue.join", "{\"capacity\":2,\"preset\":\"standard\",\"ticket\":\"standard\"}");
        assertError("s1", "BALANCE_LOW");
        assertNull(hub.peekRoomOf("10"));
    }

    /**
     * 补位成局但局未开成，门票按入座名单全额退（§廿二.3 退款路径之一）。
     */
    @Test
    void 补位成局门票按人头全额退回() {
        fund(10, 100);
        fund(20, 100);
        connect("s1", 10, null);
        connect("s2", 20, null);
        send("s1", "queue.join", "{\"capacity\":3,\"preset\":\"standard\",\"ticket\":\"standard\"}");
        send("s2", "queue.join", "{\"capacity\":3,\"preset\":\"standard\",\"ticket\":\"standard\"}");
        assertEquals(50, balance(10));
        advance(2); // 补位成组（bot 填席）→ 局未开成，全额退（§廿二.3）
        assertEquals(100, balance(10));
        assertEquals(100, balance(20));
        assertEquals("ticket-refund", last("s2", "coins.now").path("data").path("reason").asText());
    }

    /**
     * 全真人门票局不退票（ticketByTable 记账 → 首局 settle 发 ticket-win 奖励）。
     */
    @Test
    void 全真人门票局首局胜者得奖励败者不退() throws Exception {
        fund(10, 100);
        fund(20, 100);
        connect("s1", 10, null);
        connect("s2", 20, null);
        send("s1", "queue.join", "{\"capacity\":2,\"preset\":\"standard\",\"ticket\":\"standard\"}");
        send("s2", "queue.join", "{\"capacity\":2,\"preset\":\"standard\",\"ticket\":\"standard\"}");
        // 满员真人组：不退、记账上桌并自动开局
        assertEquals(50, balance(10));
        assertEquals(50, balance(20));
        send("s1", "game.place", "{\"planes\":[{\"row\":2,\"col\":2}]}");
        send("s2", "game.place", "{\"planes\":[{\"row\":7,\"col\":7}]}");
        String winnerSid = turnOf("s1").equals("10") ? "s1" : "s2";
        long winId = winnerSid.equals("s1") ? 10 : 20;
        long loseId = winId == 10 ? 20 : 10;
        finishDuel("s1", "s2");
        // 胜者 +80 门票奖励 +5 完成币；败者只剩 +5；双方都没有 ticket-refund
        assertEquals(50 + 80 + 5, balance(winId));
        assertEquals(55, balance(loseId));
        assertTrue(frames("s1", "coins.now").stream()
            .noneMatch(f -> "ticket-refund".equals(f.path("data").path("reason").asText())));
        var row = matchMapper.match(gameIdFromLedger(winId));
        assertNotNull(row);
        assertEquals("standard", row.ticket());
    }

    /**
     * 停机退款先把排队中的在付门票全退、且重复停机幂等。
     */
    @Test
    void 停机先把在付门票全退且重复停机幂等() {
        fund(10, 100);
        connect("s1", 10, null);
        FakeConn conn = conns.get("s1");
        send("s1", "queue.join", "{\"capacity\":2,\"preset\":\"standard\",\"ticket\":\"standard\"}");
        hub.shutdown();
        assertEquals(100, balance(10));
        assertTrue(conn.closed);
        hub.shutdown(); // 再停一次：Map 已删，不重复退
        assertEquals(100, balance(10));
        assertEquals(2, count("s1", "coins.now")); // fee + refund 各一条
    }

    // ================================================================ 计分与推送顺序（hub-p3）

    @Test
    void 真人匹配局按profile与rankChanged与coins顺序计分段推送() {
        connect("s1", 10, null);
        connect("s2", 20, null);
        send("s1", "queue.join", "{\"capacity\":2,\"preset\":\"standard\"}");
        send("s2", "queue.join", "{\"capacity\":2,\"preset\":\"standard\"}");
        send("s1", "game.place", "{\"planes\":[{\"row\":2,\"col\":2}]}");
        send("s2", "game.place", "{\"planes\":[{\"row\":7,\"col\":7}]}");
        String winnerSid = turnOf("s1").equals("10") ? "s1" : "s2";
        String loserSid = winnerSid.equals("s1") ? "s2" : "s1";
        finishDuel("s1", "s2");

        for (String sid : List.of(winnerSid, loserSid)) {
            List<String> evts = conns.get(sid).frames.stream()
                .map(f -> f.path("evt").asText()).toList();
            int profile = evts.lastIndexOf("profile.now");
            int rank = evts.lastIndexOf("rank.changed");
            int coins = evts.lastIndexOf("coins.now");
            assertTrue(profile >= 0 && rank > profile, sid + ": profile 必须先于 rankChanged");
            assertTrue(coins > rank, sid + ": rankChanged 必须先于 coins.now");
        }
        JsonNode win = last(winnerSid, "rank.changed");
        assertEquals(1, win.path("data").path("delta").asInt());   // 首胜 +1 星
        assertEquals("scoring", win.path("data").path("reason").asText());
        assertEquals(0, last(loserSid, "rank.changed").path("data").path("delta").asInt()); // 列兵垫底保护
        assertEquals(5, last(winnerSid, "coins.now").path("data").path("delta").asInt());
    }

    @Test
    void 人机局掉线判负发完成币但不动段位() {
        connect("s1", 10, null);
        send("s1", "practice.create", "{\"preset\":\"standard\",\"capacity\":2}"); // 1 真人 + 1 电脑
        send("s1", "game.place", "{\"planes\":[{\"row\":2,\"col\":2}]}");
        // 掉线过 duel 宽限期判负：座位保留（left=false）→ 玩家在 humans 快照里，
        // withBots=true → 记完成币、段位冻结（spec §6.2）。弃局(room.leave)不走这里：
        // 离开者被 afterEngine 从快照剔除，不计分不记账（TS hub-p3 中途离开口径）。
        hub.onDisconnect("s1");
        advance(com.timeline.game.engine.Engine.DISCONNECT_GRACE_MS + 1_000); // tick 到点判负
        // 判负时该玩家没有活会话：完成币只落账、不推送（sendToPlayer 无会话即丢弃，TS 同语义），
        // 所以这里断言账上余额而不是 coins.now 帧。
        assertEquals(5, balance(10), "人机局也要 +5 完成币（spec §6.1）");
        assertEquals(0, count("s1", "coins.now"));
        // 段位冻结：档案胜败场都不动
        var p = profiles.profile(10, null, clock.get());
        assertEquals(0, p.rank().wins());
        assertEquals(0, p.rank().losses());
        assertEquals(0, count("s1", "rank.changed"));
    }

    @Test
    void 好友房对局完全不进档案零结算零推送() throws Exception {
        connect("s1", 10, null);
        connect("s2", 20, null);
        startDuel("s1", "s2");
        finishDuel("s1", "s2");
        assertEquals(0, matchRowCount());
        assertEquals(0, count("s1", "rank.changed"));
        assertEquals(0, count("s1", "coins.now"));
        assertEquals(0, count("s2", "rank.changed"));
        assertEquals(0, count("s2", "coins.now"));
        // 桌面还是看到了名次（lastResult 广播不依赖结算）
        assertFalse(tableOf("s1").path("lastResult").isNull());
    }

    @Test
    void 结算重放不双发星币() {
        connect("s1", 10, null);
        connect("s2", 20, null);
        send("s1", "queue.join", "{\"capacity\":2,\"preset\":\"standard\"}");
        send("s2", "queue.join", "{\"capacity\":2,\"preset\":\"standard\"}");
        send("s1", "game.place", "{\"planes\":[{\"row\":2,\"col\":2}]}");
        send("s2", "game.place", "{\"planes\":[{\"row\":7,\"col\":7}]}");
        finishDuel("s1", "s2");
        int coins = count("s1", "coins.now") + count("s2", "coins.now");
        int money = balance(10) + balance(20);
        advance(10_000); // 同一局再推多次 tick：claimed=false，什么都不再发生
        assertEquals(coins, count("s1", "coins.now") + count("s2", "coins.now"));
        assertEquals(money, balance(10) + balance(20));
    }

    // ================================================================ 档案 / 榜单 / 金币（hub-p3）

    @Test
    void 握手即推档案超长昵称回退默认榜单条目不含playerId() {
        connect("s1", 10, "这是一条超过十二个字符的昵称");
        JsonNode p = last("s1", "profile.now");
        assertEquals("玩家", p.path("data").path("nickname").asText()); // 清洗失败 → 兜底
        assertEquals(1, p.path("data").path("season").asInt());
        send("s1", "profile.get", "{}");
        assertEquals(10, last("s1", "profile.now").path("data").path("userId").asLong());
        send("s1", "rank.list", "{}");
        JsonNode rl = last("s1", "rank.list");
        assertNotNull(rl);
        assertEquals(1, rl.path("data").path("season").asInt());
        assertTrue(rl.path("data").path("entries").isArray());
        for (JsonNode row : rl.path("data").path("entries")) assertFalse(row.has("playerId"));
    }

    @Test
    void 改昵称落档案并同步同桌() {
        connect("s1", 10, "小明");
        connect("s2", 20, null);
        createRoom("s1", 2, false);
        send("s2", "room.join", "{\"roomCode\":\"" + roomCodeOf("s1") + "\"}");
        send("s1", "nickname.set", "{\"nickname\":\"  新名字  \"}");
        assertEquals("新名字", last("s1", "profile.now").path("data").path("nickname").asText());
        assertEquals("新名字", tableOf("s2").path("seats").get(0).path("nickname").asText());
    }

    @Test
    void 账本拉取与广告奖励日上限QUOTA_EXCEEDED() {
        connect("s1", 10, null);
        for (int i = 0; i < 5; i++) send("s1", "coin.adReward", "{}");
        assertEquals(150, balance(10));
        assertEquals("ad", last("s1", "coins.now").path("data").path("reason").asText());
        send("s1", "coin.adReward", "{}");
        assertError("s1", "QUOTA_EXCEEDED"); // AD_LIMIT 语义收敛到 QUOTA_EXCEEDED（spec §0）
        send("s1", "coins.ledger", "{}");
        JsonNode led = last("s1", "coins.ledger");
        assertEquals(150, led.path("data").path("balance").asInt());
        assertEquals(5, led.path("data").path("ledger").size());
    }

    // ================================================================ 跨季钩子

    @Test
    void 跨季tick调钩子翻页并给在线者推season_reset无钩子时安全跳过() {
        List<Object[]> calls = new ArrayList<>();
        hub = makeHub(new Matchmaking(), cyclingCodes("111111"),
            (nowMs, batch) -> { calls.add(new Object[]{nowMs, batch}); return 0; }, null);
        connect("s1", 10, null);
        assertEquals(0, calls.size());   // connect 不 tick
        hub.tick(clock.get());
        assertEquals(1, calls.size());   // 每 tick 恰好翻页一次
        assertEquals(500, calls.get(0)[1]);
        assertEquals(0, count("s1", "rank.changed")); // 未跨季不推
        // 跨过季界（epoch + 一个整季长 + 100 才进入第 2 季，仅过 epoch 仍是第 1 季）：
        // 在线者收到 profile + rankChanged(0,'season-reset')
        clock.set(Rank.SEASON_EPOCH_MS + Rank.SEASON_MS + 100);
        hub.tick(clock.get());
        JsonNode rc = last("s1", "rank.changed");
        assertNotNull(rc);
        assertEquals("season-reset", rc.path("data").path("reason").asText());
        assertEquals(0, rc.path("data").path("delta").asInt());
        assertEquals(2, last("s1", "profile.now").path("data").path("season").asInt());
        // 钩子为 null 的 Hub：tick 正常跑、不炸（并行重构未接线时的安全缺省）
        hub = makeHub(new Matchmaking(), cyclingCodes("111111"), null, null);
        connect("s9", 90, null);
        hub.tick(clock.get());
        assertEquals(0, count("s9", "rank.changed"));
    }
}
