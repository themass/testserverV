package com.timeline.game.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.timeline.game.api.GameCommandSink;
import com.timeline.game.api.GameConnection;
import com.timeline.game.domain.Coins;
import com.timeline.game.domain.GameTypes;
import com.timeline.game.domain.Nickname;
import com.timeline.game.domain.Rank;
import com.timeline.game.domain.Rules;
import com.timeline.game.domain.Ruleset;
import com.timeline.game.engine.Engine;
import com.timeline.game.engine.EngineEvent;
import com.timeline.game.protocol.EngineEventCodec;
import com.timeline.game.protocol.GameCmd;
import com.timeline.game.protocol.GameEnvelopeCodec;
import com.timeline.game.protocol.GameErrorCode;
import com.timeline.game.protocol.GameEvt;

import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.BiFunction;
import java.util.function.DoubleSupplier;
import java.util.function.LongSupplier;
import java.util.function.Supplier;

/**
 * Hub：连接、会话、命令路由、桌管道、匹配交接、门票状态机与大厅列表（TS hub.ts 直译，spec §4）。
 *
 * <p><b>有意差异（spec §7）</b>：无 auth 命令——身份在 WS 握手期由 {@code Vpn-Token} 解析成
 * userId，建连即已认证（{@link #onConnect}）；playerId 即 userId 的十进制串（与结算侧同一口径）。
 * 同 playerId 新会话顶掉旧会话并显式 close 旧 socket；旧 socket 真正关闭时才走断线语义
 * （被顶掉的旧会话在 onDisconnect 里因归属已换而自动跳过，等价 TS 的 sessionByPlayer 校验）。
 *
 * <p><b>单线程假设（spec §6.12）</b>：本类所有方法（含 {@link #tick(long)}）必须由同一传输线程
 * 顺序调用，或经 per-instance 串行化（每桌取 {@code game:lock:table:{id}}、dispatchTable 的
 * "归因→投递→结算→sync"保持每桌原子）。类内因此不加任何锁。多实例共享桌子/队列的
 * Redis 端（design.md：{@code game:table:*}/{@code game:queue:*}）不在本类——这里保持进程内存语义，
 * 换 Redis 只换这些 Map 的实现，路由与不变式不变。
 *
 * <p>时钟：逻辑时间全部来自 {@link #nowMs}（测试注入假时钟）；类内不读墙钟（spec §1）。
 */
public final class GameHub implements GameCommandSink {

    /** 大厅列表每个专区最多推送的条目数（spec §20.6）。 */
    public static final int ROOM_LIST_MAX = 50;
    /** 同一专区两次推送的最小间隔；期间的变化合并为一次（spec §20.6）。 */
    public static final long ROOM_LIST_MIN_INTERVAL_MS = 1_000;
    /** 段位榜条数（spec §21.5）。 */
    public static final int RANK_LIST_MAX = 50;
    /** 默认昵称（握手没带平台昵称时的兜底，TS DEFAULT_NICKNAME）。 */
    public static final String DEFAULT_NICKNAME = "玩家";

    private final ObjectMapper mapper;
    private final LongSupplier nowMs;
    private final java.time.ZoneId zone;
    private final GameProfileService profiles;
    private final GameWalletService wallet;
    private final GameSettlementService settlement;
    private final Matchmaking matchmaking;
    private final Supplier<String> roomCodeSupplier;
    private final DoubleSupplier rng;

    private final Map<String, Table> tables = new LinkedHashMap<>();
    /** playerId → roomCode；只存人类（bot 永不入归因表，spec §6.7）。 */
    private final Map<String, String> tableByPlayer = new HashMap<>();
    /** roomCode → 真人成员集合（M5：sync 只遍历它，不扫全表）。 */
    private final Map<String, Set<String>> membersByTable = new HashMap<>();
    /** roomCode → 本局是否已补发开局私有快照（broadcastStart 的 {table,game} 半边，见 dispatchTable）。 */
    private final Map<String, Boolean> startSnapshotSent = new HashMap<>();
    private final Map<String, String> nicknames = new HashMap<>();

    private final Map<String, Session> sessions = new LinkedHashMap<>();
    private final Map<String, String> sessionByPlayer = new HashMap<>();

    // ------------------------------------------------ 大厅列表订阅（spec §20.6）
    /** clientId → 订阅的专区容量。 */
    private final Map<String, Integer> roomSubs = new HashMap<>();
    private final Set<Integer> roomDirty = new LinkedHashSet<>();
    private final Map<Integer, HubOutbound.RoomLast> roomLast = new HashMap<>();

    // ------------------------------------------------ 门票（spec §廿二.3）
    /** 排队中已付门票的 playerId → 门票档；成局转 ticketByTable，离队退款，二者互斥。 */
    private final Map<String, Coins.TicketId> ticketQueue = new HashMap<>();
    /** 门票桌 → 门票档与入座名单（首局未打完就关桌要按名单全退，评审 #2）。 */
    private final Map<String, HubOutbound.Booked> ticketByTable = new HashMap<>();
    /** 门票账目幂等键的单调序号（评审 #1）：同一毫秒多笔账互不吞并。 */
    private long ticketSeq = 0;

    // ------------------------------------------------ 结算接线
    /** roomCode → Hub 侧局数计数：与 Table.gamesPlayed 同步，用于开局 recordStart 的幂等 id。 */
    private final Map<String, Integer> gamesPlayedByRoom = new HashMap<>();
    /** 已 recordStart 过的局 id（一桌一局只记一次，rematch 记新局）。 */
    private final Map<String, String> recordedGameId = new HashMap<>();
    /** playerId → 上次推送时的赛季号（跨季推送去重；键恒用裸 playerId，与 onDisconnect 一致）。 */
    private final Map<String, Integer> seenSeason = new HashMap<>();
    /** 跨季钩子（可空 = tick 跳过跨季处理）：见 {@link SeasonResetHook}。 */
    private final SeasonResetHook seasonResetHook;
    /** 事务接缝（可空 = 直跑，测试/H2 autocommit 语义）：见 {@link TxRunner}。 */
    private final TxRunner txRunner;

    /**
     * 跨季重置钩子（并行重构约定）：tick 每轮先交给它做 DB 侧翻页（生产实现就是
     * {@link GameSeasonService#sweep(long, int)} 的方法引用），随后 Hub 只给在线者推
     * profile + rankChanged(0,'season-reset') 通知（TS 语义：段位卡自己刷新）。
     * Hub 不碰任何赛季持久化方法；传 null = 本轮 tick 整体跳过跨季处理。
     */
    @FunctionalInterface
    public interface SeasonResetHook {
        /** 与 GameSeasonService.sweep 同签名：翻页处理过期赛季行，返回触达用户数（多数轮为 0）。 */
        int sweep(long nowMs, int batchSize);
    }

    /**
     * 事务接缝（spec §6.12）：钱包 grant 与结算 settle/recordStart 必须同事务——
     * GameWalletService 的让渡路径假设流水行能随事务回滚。Hub 不硬依赖 Spring：
     * 装配层给 DataSourceTransactionManager 的实现，null = 直接执行（测试/H2 autocommit）。
     */
    @FunctionalInterface
    public interface TxRunner {
        <T> T run(java.util.function.Supplier<T> work);
    }

    /** 一个已认证会话（TS Session 直译；playerId 是 userId 的字符串形态）。 */
    private static final class Session {
        final String clientId;
        final GameConnection conn;
        final long userId;
        final String playerId;
        long seq;

        Session(String clientId, GameConnection conn, long userId) {
            this.clientId = clientId;
            this.conn = conn;
            this.userId = userId;
            this.playerId = String.valueOf(userId);
        }
    }

    private static final SecureRandom ROOM_RANDOM = new SecureRandom();

    /**
     * 全参构造（测试与装配层用）。
     *
     * @param seasonResetHook 跨季翻页（生产接 {@code gameSeasonService::sweep}）；null = tick 跳过跨季
     * @param txRunner        结算/开局记账的事务接缝；null = 直跑（测试/H2 autocommit）
     */
    public GameHub(ObjectMapper mapper, LongSupplier nowMs, java.time.ZoneId zone,
                   GameProfileService profiles, GameWalletService wallet,
                   GameSettlementService settlement, Matchmaking matchmaking,
                   Supplier<String> roomCodeSupplier, DoubleSupplier rng,
                   SeasonResetHook seasonResetHook, TxRunner txRunner) {
        this.mapper = mapper;
        this.nowMs = nowMs;
        this.zone = zone;
        this.profiles = profiles;
        this.wallet = wallet;
        this.settlement = settlement;
        this.matchmaking = matchmaking;
        this.roomCodeSupplier = roomCodeSupplier != null ? roomCodeSupplier : GameHub::randomRoomCode;
        this.rng = rng != null ? rng : Math::random;
        this.seasonResetHook = seasonResetHook;
        this.txRunner = txRunner;
    }

    /** 便捷构造：随机房间号 + 非确定随机源 + 无跨季钩子 + 无事务包装（测试请走全参构造注入确定性）。 */
    public GameHub(ObjectMapper mapper, LongSupplier nowMs, java.time.ZoneId zone,
                   GameProfileService profiles, GameWalletService wallet,
                   GameSettlementService settlement, Matchmaking matchmaking) {
        this(mapper, nowMs, zone, profiles, wallet, settlement, matchmaking, null, null, null, null);
    }

    private static String randomRoomCode() {
        return String.valueOf(100_000 + ROOM_RANDOM.nextInt(900_000));
    }

    // ============================================================ 连接（spec §4 生命周期）

    /**
     * 握手已过、建连即认证（有意差异：无 auth/ready/token）。
     * 顶号：同 playerId 的旧会话先摘除归属并显式 close 旧 socket；
     * 旧 socket 随后回调 onDisconnect 时因归属已指向新会话而被忽略（不影响新会话，TS 同语义）。
     * 随后是重连恢复（TS auth 尾段）：仍挂在某桌 → 无条件 setConnected(true) 派发（半开连接 I2），
     * 握手昵称覆盖离线改名（I7），最后补私有 {table, game} 快照。
     */
    @Override
    public void onConnect(String clientId, GameConnection conn, long userId, String name) {
        String playerId = String.valueOf(userId);

        String previous = sessionByPlayer.get(playerId);
        if (previous != null && !previous.equals(clientId)) {
            Session old = sessions.remove(previous);
            if (old != null) old.conn.close();
        }
        Session session = new Session(clientId, conn, userId);
        sessions.put(clientId, session);
        sessionByPlayer.put(playerId, clientId);

        // 昵称口径：握手带来的平台昵称清洗后覆盖离线改名；没带就沿用已存昵称（TS auth-nickname 语义）。
        String existing = nicknames.get(playerId);
        String name2;
        if (name != null && !name.isBlank()) {
            name2 = acceptedNickname(name, existing != null ? existing : DEFAULT_NICKNAME);
        } else {
            name2 = existing != null ? existing : DEFAULT_NICKNAME;
        }
        nicknames.put(playerId, name2);
        seenSeason.put(playerId, Rank.seasonNumber(nowMs.getAsLong()));

        // 进大厅即推档案（spec §21.9）。有意差异：TS 的登录礼/跨季发币在 Java 侧归
        // 离线批处理与 HTTP 首屏建档（GameProfileService.profile），WS 不再发账。
        sendToPlayer(playerId, GameEvt.PROFILE_NOW, null,
            HubOutbound.profileNode(mapper, profiles.profile(userId, name2, nowMs.getAsLong())));

        Table table = tableOf(playerId);
        if (table != null) {
            dispatchTable(table, table.setConnected(playerId, true, nowMs.getAsLong()));
            if (tableOf(playerId) == table && name != null && !name.isBlank()) {
                // 离线期间改过名：以握手昵称为准（评审 I7）
                Table after = tableOf(playerId);
                for (GameTypes.SeatView s : after.view().seats()) {
                    if (s != null && s.playerId().equals(playerId) && !s.nickname().equals(name2)) {
                        dispatchTable(after, after.setNickname(playerId, name2));
                        break;
                    }
                }
            }
            Table still = tableOf(playerId);
            if (still != null && still == table) {
                deliverSnapshot(still, playerId);
            }
        }
    }

    /** 断线（TS disconnect）：删会话（被顶掉则忽略）→ 离队退款 → 桌子记掉线（不踢座位）。 */
    @Override
    public void onDisconnect(String clientId) {
        Session session = sessions.remove(clientId);
        if (session == null) return;
        roomSubs.remove(clientId);
        String playerId = session.playerId;
        // 被顶掉的旧会话断开：归属已指向新会话，不影响新会话
        if (!clientId.equals(sessionByPlayer.get(playerId))) return;
        sessionByPlayer.remove(playerId);
        long now = nowMs.getAsLong();

        dropQueue(playerId);

        Table table = tableOf(playerId);
        if (table != null) dispatchTable(table, table.setConnected(playerId, false, now));
    }

    // ============================================================ 命令路由（19 条 cmd）

    @Override
    public void onCommand(String clientId, GameEnvelopeCodec.Inbound cmd) {
        Session session = sessions.get(clientId);
        if (session == null) return;   // 会话已关：迟到的在途帧静默丢弃
        route(session, cmd);
    }

    private void route(Session session, GameEnvelopeCodec.Inbound in) {
        String playerId = session.playerId;
        long now = nowMs.getAsLong();
        JsonNode data = in.data() == null ? mapper.createObjectNode() : in.data();
        GameCmd cmd = in.cmd();
        Table table = tableOf(playerId);

        switch (cmd) {
            case PROFILE_GET -> {
                send(session, GameEvt.PROFILE_NOW, in.seq(),
                    HubOutbound.profileNode(mapper,
                        profiles.profile(session.userId, nicknameOf(playerId), now)));
            }
            case NICKNAME_SET -> {
                JsonNode raw = data.get("nickname");
                GameErrorCode bad = profiles.setNickname(session.userId,
                    raw != null && raw.isTextual() ? raw.textValue() : null);
                if (bad != null) {
                    error(session, in.seq(), bad, "昵称不合法");
                    return;
                }
                String cleaned = Nickname.sanitizeNickname(
                    raw != null && raw.isTextual() ? raw.textValue() : null, nicknameOf(playerId));
                nicknames.put(playerId, cleaned);
                send(session, GameEvt.PROFILE_NOW, in.seq(),
                    HubOutbound.profileNode(mapper, profiles.profile(session.userId, cleaned, now)));
                if (table != null) dispatchTable(table, table.setNickname(playerId, cleaned));
            }
            case ROOM_CREATE -> {
                Integer capacity = capacity(data);
                if (capacity == null) { error(session, in.seq(), GameErrorCode.BAD_SHAPE, "capacity 需为 2/3/4"); return; }
                Ruleset.RuleSet rules = rulesFrom(data);
                if (rules == null) { error(session, in.seq(), GameErrorCode.BAD_RULES, "规则非法"); return; }
                boolean listed = data.path("listed").isBoolean() && data.get("listed").asBoolean();
                if (!leaveCurrent(session, false)) return;
                dropRoomSub(session.clientId);
                joinTable(newTable(GameTypes.TableKind.FRIEND, capacity, rules, listed, null),
                    List.of(playerId), 0, null);
            }
            case ROOM_JOIN -> joinRoomMaybeListed(session, in, data);
            case ROOM_LIST -> {
                // 订阅式（protocol.md）：subscribe=true 立即回快照并记基线；false 退订（未订阅时静默）
                boolean subscribe = data.path("subscribe").isBoolean() && data.get("subscribe").asBoolean();
                if (!subscribe) { roomSubs.remove(session.clientId); return; }
                Integer capacity = capacity(data);
                if (capacity == null) { error(session, in.seq(), GameErrorCode.BAD_SHAPE, "capacity 需为 2/3/4"); return; }
                roomSubs.put(session.clientId, capacity);
                List<GameTypes.RoomListEntry> entries = roomSnapshot(capacity);
                send(session, GameEvt.ROOM_LIST, in.seq(),
                    HubOutbound.roomListNode(mapper, capacity, HubOutbound.roomListEntries(mapper, entries)));
                roomLast.put(capacity, new HubOutbound.RoomLast(
                    HubOutbound.roomListEntries(mapper, entries).toString(), now));
            }
            case QUEUE_JOIN -> queueJoin(session, in, data);
            case QUEUE_LEAVE -> queueLeave(session, in.seq());
            case PRACTICE_CREATE -> {
                Ruleset.PresetId preset = preset(data.get("preset"));
                if (preset == null) { error(session, in.seq(), GameErrorCode.BAD_SHAPE, "preset 缺失"); return; }
                int capacity = data.path("capacity").isInt() && data.get("capacity").asInt() >= 2
                    && data.get("capacity").asInt() <= 4 ? data.get("capacity").asInt() : 2;
                if (!leaveCurrent(session, false)) return;
                dropRoomSub(session.clientId);
                Table practice = newTable(GameTypes.TableKind.PRACTICE, capacity,
                    Ruleset.PRESETS.get(preset), false, preset);
                // 练习桌（spec §20.4）：自己一个真人 + capacity−1 个电脑，难度取档位预设
                joinTable(practice, List.of(playerId), capacity - 1, preset);
            }
            case RANK_LIST -> {
                send(session, GameEvt.RANK_LIST, in.seq(),
                    HubOutbound.rankListNode(mapper, Rank.seasonNumber(now), profiles.rankList(RANK_LIST_MAX, now)));
            }
            case COINS_LEDGER -> send(session, GameEvt.COINS_LEDGER, in.seq(),
                HubOutbound.ledgerNode(mapper, profiles.coinsLedger(session.userId)));
            case COIN_AD_REWARD -> {
                // 与 HTTP POST /coins/ad-reward 同一实现（api.md：离线写与 WS 行为一致）
                GameProfileService.AdRewardResult r = profiles.adReward(session.userId, now);
                if (r.error() != null) { error(session, in.seq(), r.error(), "广告奖励失败"); return; }
                sendToPlayer(playerId, GameEvt.COINS_NOW, in.seq(),
                    HubOutbound.coinsNowNode(mapper, r.granted(), "ad", r.balance(), false));
            }
            case GAME_ITEM -> error(session, in.seq(), GameErrorCode.UNSUPPORTED, "道具未开放");
            default -> {
                // 其余全部要求有桌
                if (table == null) { error(session, in.seq(), GameErrorCode.NOT_IN_ROOM, "不在房间中"); return; }
                switch (cmd) {
                    case ROOM_RULES -> {
                        Ruleset.RuleSet rules = rulesFrom(data.has("rules") ? data.get("rules") : data);
                        if (rules == null) { error(session, in.seq(), GameErrorCode.BAD_RULES, "规则非法"); return; }
                        dispatchTable(table, table.updateRules(playerId, rules, now));
                    }
                    case ROOM_READY -> {
                        boolean ready = !data.has("ready") || data.get("ready").asBoolean(false);
                        int rulesVersion = data.path("rulesVersion").isInt()
                            ? data.get("rulesVersion").asInt() : table.rulesVersion();
                        dispatchTable(table, table.setReady(playerId, ready, rulesVersion, now));
                    }
                    case ROOM_LISTED -> {
                        boolean listed = data.path("listed").isBoolean() && data.get("listed").asBoolean();
                        dispatchTable(table, table.setListed(playerId, listed));
                    }
                    case ROOM_KICK -> {
                        String target = kickTarget(table, data);
                        if (target == null) { error(session, in.seq(), GameErrorCode.TARGET_NOT_FOUND, "目标不在房间中"); return; }
                        // kick 释放座位 → dispatchTable 末尾的 sync 依成员集合解除被踢者归属，
                        // 之后的广播不再投给他（kicked 本身在释放前送达）。
                        dispatchTable(table, table.kick(playerId, target, now));
                    }
                    case ROOM_LEAVE -> leaveTable(table, playerId);
                    case GAME_PLACE -> {
                        List<Rules.Cell> cells = cells(data.get("planes"));
                        if (cells == null) { error(session, in.seq(), GameErrorCode.BAD_SHAPE, "planes 形状非法"); return; }
                        dispatchTable(table, table.handleGame(playerId, new Engine.GameCommand.Place(cells), now));
                    }
                    case GAME_FIRE -> {
                        JsonNode row = data.get("row"), col = data.get("col");
                        if (row == null || !row.isIntegralNumber() || col == null || !col.isIntegralNumber()) {
                            error(session, in.seq(), GameErrorCode.BAD_SHAPE, "row/col 缺失");
                            return;
                        }
                        dispatchTable(table, table.handleGame(playerId,
                            new Engine.GameCommand.Fire(row.asInt(), col.asInt()), now));
                    }
                    default -> error(session, in.seq(), GameErrorCode.UNKNOWN_CMD, "命令不支持");
                }
            }
        }
    }

    // ============================================================ 加入路径（RF#5：失败不赶人）

    private void joinRoom(Session session, GameEnvelopeCodec.Inbound in, String roomCode) {
        String playerId = session.playerId;
        long now = nowMs.getAsLong();
        Table current = tableOf(playerId);
        // 已在这张桌上：Table.join 只补发快照
        if (current != null && current.roomCode().equals(roomCode)) {
            dispatchTable(current, current.join(playerId, nicknameOf(playerId), now));
            return;
        }
        if (current != null && current.phase() == GameTypes.TablePhase.IN_GAME) {
            error(session, in.seq(), GameErrorCode.ALREADY_IN_ROOM, "对局进行中");
            return;
        }
        // 目标进不去时不要先把人从原来的桌上拉走（Review Focus #5）
        Table target = roomCode == null ? null : tables.get(roomCode);
        if (target == null || target.closed()) {
            error(session, in.seq(), GameErrorCode.ROOM_NOT_FOUND, "房间不存在");
            return;
        }
        GameErrorCode admit = target.canJoin(playerId);
        if (admit != null) {
            error(session, in.seq(), admit,
                admit == GameErrorCode.BANNED ? "已被房主移出房间" : "无法加入房间");
            return;
        }
        if (!leaveCurrent(session, false)) return;
        dropRoomSub(session.clientId);
        joinTable(target, List.of(playerId), 0, null);
    }

    /** 按列表条目加入（spec §20.6）：只认公开且可进的桌；失败时不动玩家现在的位置（RF#5）。 */
    private void joinListed(Session session, long seq, String tableId) {
        String playerId = session.playerId;
        long now = nowMs.getAsLong();
        Table target = null;
        for (Table t : tables.values()) {
            if (t.tableId().equals(tableId)) { target = t; break; }
        }
        Table current = tableOf(playerId);
        // 已经在这张桌上：只补发快照，不能走"离开再进"（房主会被自己触发让位）
        if (current != null && current.tableId().equals(tableId)) {
            dispatchTable(current, current.join(playerId, nicknameOf(playerId), now));
            return;
        }
        if (target == null || target.closed()) {
            error(session, seq, GameErrorCode.ROOM_NOT_FOUND, "房间不存在或已关闭");
            return;
        }
        if (current != null && current.phase() == GameTypes.TablePhase.IN_GAME) {
            error(session, seq, GameErrorCode.ALREADY_IN_ROOM, "对局进行中");
            return;
        }
        // listing() 为空且不是"满座/对局中"这种可理解的原因 → 桌不公开，等同不存在
        if (target.listing() == null
            && !(target.phase() == GameTypes.TablePhase.IN_GAME || target.members().size() >= target.capacity())) {
            error(session, seq, GameErrorCode.ROOM_NOT_FOUND, "房间不存在或已关闭");
            return;
        }
        GameErrorCode admit = target.canJoin(playerId);
        if (admit != null) {
            error(session, seq, admit, admit == GameErrorCode.ROOM_FULL ? "房间已满" : "无法加入房间");
            return;
        }
        if (!leaveCurrent(session, false)) return;
        dropRoomSub(session.clientId);
        joinTable(target, List.of(playerId), 0, null);
    }

    /** 房间号加入也接受列表语义：room.join 里若给了 tableId 而非 roomCode，走 joinListed。 */
    private void joinRoomMaybeListed(Session session, GameEnvelopeCodec.Inbound in, JsonNode data) {
        if (data.path("tableId").isTextual()) {
            joinListed(session, in.seq(), data.get("tableId").textValue());
            return;
        }
        joinRoom(session, in, data.path("roomCode").isTextual() ? data.get("roomCode").textValue() : null);
    }

    /**
     * 离开当前的等候桌与队列；对局中回 ALREADY_IN_ROOM 并返回 false。
     * keepQueue：排队换桌时由 Matchmaking 自己处理换队列（TS leaveCurrent 同参数）。
     */
    private boolean leaveCurrent(Session session, boolean keepQueue) {
        String playerId = session.playerId;
        Table table = tableOf(playerId);
        if (table != null) {
            if (table.phase() == GameTypes.TablePhase.IN_GAME) {
                error(session, 0, GameErrorCode.ALREADY_IN_ROOM, "对局进行中");
                return false;
            }
            leaveTable(table, playerId);
        }
        if (!keepQueue) dropQueue(playerId);
        return true;
    }

    private void leaveTable(Table table, String playerId) {
        dispatchTable(table, table.leave(playerId, nowMs.getAsLong()));
        if (table.roomCode().equals(tableByPlayer.get(playerId))) tableByPlayer.remove(playerId);
    }

    private void queueLeave(Session session, long seq) {
        if (matchmaking.queueOf(session.playerId) == null) {
            error(session, seq, GameErrorCode.NOT_IN_QUEUE, "不在队列中");
            return;
        }
        dropQueue(session.playerId);
    }

    /** 离开队列并退还在付门票（§廿二.3：成局前退款；断线/换队/主动退都走这里）。 */
    private void dropQueue(String playerId) {
        for (QueueOutbound o : matchmaking.leave(playerId, nowMs.getAsLong())) deliverQueue(o);
        refundTicket(playerId);
    }

    // ============================================================ 门票状态机（spec §4 / §6.1）

    private void refundTicket(String playerId) {
        Coins.TicketId ticket = ticketQueue.remove(playerId);
        if (ticket == null) return;
        creditTicketRefund(playerId, ticket);
    }

    /** 退款一笔：调用方已从 ticketQueue/ticketByTable 认领过这张票，防重复退。 */
    private void creditTicketRefund(String playerId, Coins.TicketId ticket) {
        long now = nowMs.getAsLong();
        // 退款豁免净增上限（Coins.netExempt）；幂等键带单调序号（评审 #1）——
        // 同一毫秒的两笔退款各退各的票，不互相吞；防重复退靠的是调用方的 Map remove
        long seq = ++ticketSeq;
        GameWalletService.GrantResult r = settlement.refundTicket(Long.parseLong(playerId), ticket,
            playerId + ":" + now + ":" + seq, now);
        // applied=0 不推空账变（评审 #6）：否则结算页出现"+0"闪条并覆盖有效提示
        if (r.applied() == 0) return;
        sendToPlayer(playerId, GameEvt.COINS_NOW, null,
            HubOutbound.coinsNowNode(mapper, r.applied(), "ticket-refund", r.balance(), false));
    }

    /** 队列成组 → 入座后的门票结算（§廿二.3）：补位局全退；纯真人局记在桌上，首局按胜负发奖。 */
    private void settleQueueIntoTable(Matchmaking.Grouped group, String roomCode) {
        Coins.TicketId ticket = group.key().ticket();
        if (ticket == null || ticket == Coins.TicketId.FREE) return;
        long now = nowMs.getAsLong();
        if (group.playerIds().size() < group.key().capacity()) {
            // 补位成局：门票全额退款、不给奖励（电脑局不产金币奖励）
            for (String id : group.playerIds()) {
                if (ticket == ticketQueue.get(id)) refundTicket(id);
            }
            return;
        }
        for (String id : group.playerIds()) {
            if (ticket != ticketQueue.get(id)) continue;
            ticketQueue.remove(id);
            // 真人门票局开局计数（补位退款不计数）；配额上限已在入队时用 canPlayTicket 把关
            wallet.bumpTicketPlays(Long.parseLong(id), now, zone);
        }
        ticketByTable.put(roomCode, new HubOutbound.Booked(ticket, List.copyOf(group.playerIds())));
    }

    // ============================================================ 桌子管道（spec §4）

    private Table newTable(GameTypes.TableKind kind, int capacity, Ruleset.RuleSet rules,
                           boolean listed, Ruleset.PresetId preset) {
        String roomCode = uniqueRoomCode();
        AtomicInteger botSeq = new AtomicInteger();
        BiFunction<String, Integer, GameBot> botFactory = (difficulty, index) -> new BotPlayer(
            Table.BOT_ID_PREFIX + roomCode + ":" + index + ":" + botSeq.incrementAndGet(),
            Ruleset.PresetId.valueOf(difficulty), rng);
        Table.Options opts = new Table.Options(roomCode, kind, capacity, rules, nowMs.getAsLong(),
            listed, null, botFactory, rng, preset);
        Table table = new Table(opts);
        tables.put(roomCode, table);
        membersByTable.put(roomCode, new HashSet<>());
        gamesPlayedByRoom.put(roomCode, 0);
        return table;
    }

    /**
     * 按顺序入座；归因注册以"进桌后 members 里有它"为准（bot id 不进归属表）。
     * 逐个派发；botSeats > 0 时按同一难度补电脑座位（spec §20.4/§20.5）。
     */
    private void joinTable(Table table, List<String> playerIds, int botSeats, Ruleset.PresetId botDifficulty) {
        long now = nowMs.getAsLong();
        for (String id : playerIds) {
            List<TableOutbound> out = table.join(id, nicknameOf(id), now);
            if (table.members().contains(id)) {
                tableByPlayer.put(id, table.roomCode());
                membersByTable.get(table.roomCode()).add(id);
            }
            dispatchTable(table, out);
        }
        if (botDifficulty == null) botDifficulty = Ruleset.PresetId.BEGINNER;
        for (int i = 0; i < botSeats; i++) dispatchTable(table, table.addBot(botDifficulty, now));
    }

    private String uniqueRoomCode() {
        for (int i = 0; i < 100; i++) {
            String code = roomCodeSupplier.get();
            if (!tables.containsKey(code)) return code;
        }
        throw new IllegalStateException("无法生成唯一房间号");
    }

    private Table tableOf(String playerId) {
        String code = tableByPlayer.get(playerId);
        return code == null ? null : tables.get(code);
    }

    private String nicknameOf(String playerId) {
        return nicknames.getOrDefault(playerId, DEFAULT_NICKNAME);
    }

    /**
     * 牌桌产生的消息只投给仍属于该桌的玩家（I4：防止旧桌的消息打进玩家正在进行的新对局）。
     * 顺序固定（spec §4，不可调换）：
     * 1. 归因闸门投递（例外：桌已 closed 且收件人无归因——roomClosed/kicked 的"告别例外"）；
     * 2. gameOver → 先结算再 sync——留下的人此刻还挂在归属表上；
     * 3. sync 清归因、删关桌、退门票；
     * 4. 好友桌任何变化 → 该容量列表标脏，由 tick 合并推送。
     */
    private void dispatchTable(Table table, List<TableOutbound> out) {
        boolean ended = false;
        for (TableOutbound o : out) {
            String code = tableByPlayer.get(o.to());
            boolean deliverable = code != null ? code.equals(table.roomCode()) : table.closed();
            if (deliverable) deliver(o);
            if (o.event() instanceof TableEvent.FromEngine fe
                && fe.event() instanceof EngineEvent.GameOver) ended = true;
        }
        // broadcastStart 的 state 半边（TS 唯一让客户端提前拿到摆放 deadlineAt 的地方）：
        // sealed TableEvent 没有携带 game 视图的变体，桌层只广播 tableState；开局这一刻由 Hub
        // 按人补发私有 {table, game} 快照（与重连恢复同一条通路）。每局只补一次。
        if (table.phase() == GameTypes.TablePhase.IN_GAME
            && !startSnapshotSent.getOrDefault(table.roomCode(), false)) {
            startSnapshotSent.put(table.roomCode(), true);
            // 有意差异：TS 只给开局在座者发 state；这里对局中后来入座者同样补一份私有快照——
            // table.state 不带 game 节点，晚进者否则要等下一条引擎事件才能渲染摆放倒计时。
            for (String id : table.humanMembers()) deliverSnapshot(table, id);
        }
        // P3 计分（spec §21.2）：结算放在投递之后、sync 之前——留下的人此刻还挂在归属表上
        if (ended) {
            scoreTable(table);
            gamesPlayedByRoom.merge(table.roomCode(), 1, Integer::sum);
            // 下一局（rematch 或匹配桌续局）开局时要再补一次私有快照
            startSnapshotSent.remove(table.roomCode());
        }
        recordStartIfNeeded(table);
        sync(table);
        if (table.kind() == GameTypes.TableKind.FRIEND) roomDirty.add(table.capacity());
    }

    /** 让出座位的人解除归属；关闭的桌子整个删除（I4）。M5：只遍历本桌成员集合。 */
    private void sync(Table table) {
        List<String> members = table.closed() ? List.of() : table.humanMembers();
        Set<String> set = membersByTable.get(table.roomCode());
        if (set != null) {
            for (String id : List.copyOf(set)) {
                if (!members.contains(id)) {
                    set.remove(id);
                    if (table.roomCode().equals(tableByPlayer.get(id))) tableByPlayer.remove(id);
                }
            }
        } else {
            // 兜底：集合丢失时退回全表扫描（不应发生，但归属错误比扫描昂贵更糟）
            for (String id : List.copyOf(tableByPlayer.keySet())) {
                if (table.roomCode().equals(tableByPlayer.get(id)) && !members.contains(id)) {
                    tableByPlayer.remove(id);
                }
            }
        }
        if (table.closed()) {
            membersByTable.remove(table.roomCode());
            startSnapshotSent.remove(table.roomCode());
            if (tables.get(table.roomCode()) == table) tables.remove(table.roomCode());
            gamesPlayedByRoom.remove(table.roomCode());
            recordedGameId.remove(table.roomCode());
            // 评审 #2：门票桌首局没打完就关了（等人时全员离席/中途弃局无 gameOver）——
            // 座位快照已没意义，按入座名单全额退款（§廿二.3 中途流局退款）
            HubOutbound.Booked booked = ticketByTable.remove(table.roomCode());
            if (booked != null) {
                for (String id : booked.ids()) creditTicketRefund(id, booked.ticket());
            }
        }
    }

    /**
     * 对局结束后的档案接线（spec §4）：簿记全部委托 {@link GameSettlementService#settle}
     * （抢占幂等、战绩、完成币、门票胜奖都在它内部按 data-model.md 落库）；
     * Hub 只做两件事：组 GameContext（含"仅首局门票、bot 局 withBots"的判定）与推送顺序
     * ——每人 profile（已含最终余额）→ rankChanged（仅计分段）→ coinsChanged。
     * friend 桌完全不记账。
     *
     * <p>有意差异：TS 会为每笔 ticket-win 单独推 coinsChanged；Java 侧 settle 的 PlayerDelta
     * 只回报完成币，门票胜奖已计入钱包——profile 推送在 settle 之后读档，余额里已含胜奖，
     * 客户端账变提示合并为一条（流水明细走 coins.ledger）。
     */
    private void scoreTable(Table table) {
        if (table.kind() == GameTypes.TableKind.FRIEND) return;
        Table.LastGame game = table.lastGame();
        if (game == null) return;
        // 中途离开者不在快照里：不计分也不记战绩（用 afterEngine 时刻的快照，close 可能已清座）
        List<String> humanIds = game.humans();
        if (humanIds.isEmpty()) return;
        long now = nowMs.getAsLong();
        boolean withBots = table.kind() == GameTypes.TableKind.PRACTICE || !game.result().botIds().isEmpty();

        // 门票结算（§廿二.3）：门票桌首局按胜负——胜者拿固定奖励、败者只损失已付门票；
        // rematch 是免费普通局。booked 只在全真人成组时登记，此刻按首局消费。
        HubOutbound.Booked booked = ticketByTable.remove(table.roomCode());
        Coins.TicketId ticket = (booked != null && !withBots) ? booked.ticket() : null;
        if (booked != null && withBots) {
            // 理论上不发生（门票只随全真人组入桌）；防御性退款，票不打水漂
            for (String id : booked.ids()) creditTicketRefund(id, booked.ticket());
        }

        List<Long> humans = new ArrayList<>(humanIds.size());
        for (String id : humanIds) {
            try {
                humans.add(Long.parseLong(id));
            } catch (NumberFormatException ignored) {
                // 非 userId 形态的 playerId（握手鉴权保证不会出现）：跳过不计分
            }
        }
        if (humans.isEmpty()) return;

        GameSettlementService.GameContext ctx = new GameSettlementService.GameContext(
            game.id(), table.kind(), game.mode().name().toLowerCase(),
            game.preset() == null ? null : game.preset().name().toLowerCase(),
            table.capacity(), ticket, humans,
            // LastGame.result 是桌子级 TableResult(reason,ranking,botIds)；
            // 结算上下文只要对局结果本体（botIds 已折进 withBots 判定），名次序原样保留。
            new GameTypes.GameResult(game.result().reason(), game.result().ranking()),
            withBots, now);
        GameSettlementService.SettleOutcome outcome = inTx(() -> settlement.settle(ctx));
        // claimed=false：重放（同一 tableId:gamesPlayed 已结过），星/币不双发、也不再推
        if (!outcome.claimed()) return;

        Map<Long, GameSettlementService.PlayerDelta> byUser = new HashMap<>();
        for (GameSettlementService.PlayerDelta d : outcome.deltas()) byUser.put(d.userId(), d);

        // 先全簿记（settle 内部完成）后全推送；profile 必须带最终余额（spec §6.4）
        for (Long uid : humans) {
            String pid = String.valueOf(uid);
            GameProfileService.ProfileView view = profiles.profile(uid, nicknameOf(pid), now);
            sendToPlayer(pid, GameEvt.PROFILE_NOW, null, HubOutbound.profileNode(mapper, view));
            GameSettlementService.PlayerDelta d = byUser.get(uid);
            if (d == null) continue;
            if (!withBots && view.rank() != null) {
                sendToPlayer(pid, GameEvt.RANK_CHANGED, null, HubOutbound.rankChangedNode(mapper,
                    d.deltaStar(), view.rank().tier(), view.rank().stars(),
                    view.rank().lossStreak(), "scoring"));
            }
            if (d.coinApplied() != 0) {
                int balance = view.coins() == null ? 0 : view.coins().balance();
                sendToPlayer(pid, GameEvt.COINS_NOW, null,
                    HubOutbound.coinsNowNode(mapper, d.coinApplied(), "game", balance, d.coinCapped()));
            }
        }
    }

    /**
     * 开局落账（recordStart 骨架行，data-model.md）：桌进入 inGame 的第一时间按座位序记
     * game_match + 骨架行，gameId 与 Table 的幂等键同式（tableId:gamesPlayed），
     * gameOver 时 settle 靠同一 id 抢占。friend 桌完全不记。
     *
     * <p>有意差异：design.md 要求 recordStart 与开局同事务；桌子不暴露开局钩子，
     * Hub 在同一批 dispatch 内紧随其后补记，单实例语义等价（事务边界归装配层）。
     */
    private void recordStartIfNeeded(Table table) {
        if (table.kind() == GameTypes.TableKind.FRIEND) return;
        if (table.phase() != GameTypes.TablePhase.IN_GAME || table.engine() == null) return;
        int played = gamesPlayedByRoom.getOrDefault(table.roomCode(), 0);
        String gameId = table.tableId() + ":" + played;
        if (gameId.equals(recordedGameId.get(table.roomCode()))) return;
        recordedGameId.put(table.roomCode(), gameId);

        List<Long> seatUsers = new ArrayList<>();
        for (GameTypes.SeatView s : table.view().seats()) {
            if (s == null || s.bot()) { seatUsers.add(null); continue; }
            try {
                seatUsers.add(Long.parseLong(s.playerId()));
            } catch (NumberFormatException e) {
                seatUsers.add(null);
            }
        }
        HubOutbound.Booked booked = ticketByTable.get(table.roomCode());
        final String ticketKey = booked == null ? null : booked.ticket().name().toLowerCase();
        // recordStart 与开局其余动作同事务（spec §6.12）；txRunner=null 直跑（测试/H2 autocommit）
        inTx(() -> {
            settlement.recordStart(gameId, Rank.seasonNumber(nowMs.getAsLong()),
                table.engine().mode().name().toLowerCase(),
                table.preset() == null ? null : table.preset().name().toLowerCase(),
                table.capacity(), ticketKey,
                table.rules().boardSize(), table.rules().planeCount(), nowMs.getAsLong(), seatUsers);
            return null;
        });
    }

    /** 事务接缝：txRunner=null（测试/H2 autocommit）时直跑。 */
    private <T> T inTx(java.util.function.Supplier<T> work) {
        return txRunner == null ? work.get() : txRunner.run(work);
    }

    // ============================================================ 出站编码（spec §0 wire 映射）

    /** 投递一条桌子出站：归因过滤已在 dispatchTable 做完，这里只管编码与发送。 */
    private void deliver(TableOutbound o) {
        Session session = sessionOf(o.to());
        if (session == null) return;   // 无会话（离线/bot）：档案改动不丢，上线时补发
        TableEvent ev = o.event();
        switch (ev) {
            case TableEvent.TableState ts ->
                send(session, GameEvt.TABLE_STATE, null, HubOutbound.tableNode(mapper, ts.table()));
            case TableEvent.Closed c ->
                send(session, GameEvt.TABLE_CLOSED, null, null);
            case TableEvent.Kicked k ->
                send(session, GameEvt.TABLE_KICKED, null, HubOutbound.kickedNode(mapper, k.roomCode()));
            case TableEvent.FromEngine fe -> {
                // 桌子级错误（NOT_IN_ROOM/STALE_RULES/TARGET_READY…）与引擎事件同一条通路：
                // FromEngine(EngineEvent.Error(code,message))——这里统一编码成 wire error（spec §0）。
                EngineEventCodec.Encoded enc = EngineEventCodec.encode(mapper, fe.event());
                send(session, enc.evt(), null, enc.data());
            }
        }
    }

    /** 私有 {table, game} 全量快照（有意差异：借 table.state 下发，data 带 game 节点，见 Table 类注释）。 */
    private void deliverSnapshot(Table table, String playerId) {
        Session session = sessionOf(playerId);
        if (session == null) return;
        send(session, GameEvt.TABLE_STATE, null, HubOutbound.snapshotNode(mapper, table.snapshotFor(playerId)));
    }

    private void deliverQueue(QueueOutbound o) {
        Session session = sessionOf(o.to());
        if (session == null) return;
        switch (o.event()) {
            case QueueEvent.Status s ->
                send(session, GameEvt.QUEUE_STATUS, null, HubOutbound.queueStatusNode(mapper, s));
            case QueueEvent.Timeout t ->
                send(session, GameEvt.QUEUE_TIMEOUT, null, null);
        }
    }

    /** 向某玩家当前会话单点投递（无会话则丢弃）。 */
    private void sendToPlayer(String playerId, GameEvt evt, Long ref, ObjectNode data) {
        Session session = sessionOf(playerId);
        if (session != null) send(session, evt, ref, data);
    }

    private Session sessionOf(String playerId) {
        String sid = sessionByPlayer.get(playerId);
        return sid == null ? null : sessions.get(sid);
    }

    private void send(Session session, GameEvt evt, Long ref, ObjectNode data) {
        session.conn.send(GameEnvelopeCodec.encode(mapper, evt, ++session.seq, ref, data));
    }

    private void error(Session session, long ref, GameErrorCode code, String message) {
        // 命令触发的错误回 ref；生命周期触发的（leaveCurrent）无 ref，ref 传 0 表示无回执关联
        session.conn.send(GameEnvelopeCodec.encodeError(mapper, code, message,
            ++session.seq, ref == 0 ? null : ref));
    }

    // ============================================================ 匹配（spec §3 交接协议）

    private void queueJoin(Session session, GameEnvelopeCodec.Inbound in, JsonNode data) {
        String playerId = session.playerId;
        long now = nowMs.getAsLong();
        Integer capacity = capacity(data);
        Ruleset.PresetId preset = preset(data.get("preset"));
        if (capacity == null || preset == null) {
            error(session, in.seq(), GameErrorCode.BAD_SHAPE, "capacity/preset 缺失");
            return;
        }
        Coins.TicketId ticket = data.has("ticket")
            ? (presetTicket(data.get("ticket"))) : Coins.TicketId.FREE;
        if (data.has("ticket") && ticket == null) {
            error(session, in.seq(), GameErrorCode.BAD_SHAPE, "ticket 非法");
            return;
        }
        // 同队列重复入队是 no-op（不重扣门票）
        Matchmaking.QueueKey prev = matchmaking.queueOf(playerId);
        boolean sameQueue = prev != null && prev.capacity() == capacity
            && prev.preset() == preset
            && (prev.ticket() == null ? Coins.TicketId.FREE : prev.ticket()) == ticket;
        if (sameQueue) return;

        if (!leaveCurrent(session, true)) return;
        dropRoomSub(session.clientId);
        // 换队列：旧门票先退（§廿二.3 成局前退款）
        if (ticketQueue.containsKey(playerId)) refundTicket(playerId);

        if (ticket != Coins.TicketId.FREE) {
            // P4 门票预付（§廿二.3）：付了才排队；日配额 20/日
            if (!wallet.canPlayTicket(session.userId, now, zone)) {
                error(session, in.seq(), GameErrorCode.QUOTA_EXCEEDED, "今日门票局场次已达上限");
                return;
            }
            // 幂等键带单调序号（评审 #1）：同一毫秒 standard↔advanced 互切时，
            // 只用 now 会让第二笔撞上前一笔的 id、被幂等吞成 applied=0 → 白嫖高档票
            long feeSeq = ++ticketSeq;
            int fee = Coins.TICKETS.get(ticket).fee();
            GameWalletService.GrantResult r = wallet.grant(session.userId, new Coins.CoinOp(
                Coins.CoinReason.TICKET_FEE,
                "ticket-fee:" + playerId + ":" + now + ":" + feeSeq, playerId, now, -fee), zone);
            if (r.insufficient()) {
                error(session, in.seq(), GameErrorCode.BALANCE_LOW, "金币不足，无法支付门票");
                return;
            }
            if (r.applied() == 0) {
                error(session, in.seq(), GameErrorCode.BALANCE_LOW, "门票扣费异常");
                return;
            }
            sendToPlayer(playerId, GameEvt.COINS_NOW, in.seq(),
                HubOutbound.coinsNowNode(mapper, r.applied(), "ticket-fee", r.balance(), false));
            ticketQueue.put(playerId, ticket);
        }

        // 匹配按隐藏 MMR 分桶（spec §21.2）。
        // 有意差异：ProfileView 不暴露 mmr（档案出参刻意隐藏匹配分），Hub 拿不到实时 MMR，
        // 按 INITIAL_MMR 入队——同池玩家分桶仍一致，闸门语义不变。
        int mmr = Rank.INITIAL_MMR;
        // v4 兼容：客户端没带 ticket 就沿用无 ticket 的旧队列键（queueStatus 也不带该字段）
        Matchmaking.QueueKey key = data.has("ticket")
            ? new Matchmaking.QueueKey(capacity, preset, ticket)
            : new Matchmaking.QueueKey(capacity, preset);
        Matchmaking.JoinResult join = matchmaking.join(playerId, key, now, mmr);
        for (QueueOutbound o : join.out()) deliverQueue(o);
        if (join.group() != null) formMatch(session, join.group());
    }

    /**
     * 成组交接（spec §3）：newTable('match') → 门票记账 → joinTable（组序进人 + 按档位难度补 bot）。
     *
     * <p>有意差异（TS 是"入座后"再记账）：Java 侧 recordStart 在开局那一刻就要写 ticket 列，
     * 而满员真人桌会在 joinTable 的最后一人入座时自动开局——门票必须先于入座落到
     * ticketByTable，否则首局的 game_match.ticket 恒写成 free。退款/计数路径只读
     * ticketQueue 与组名单，不依赖成员表，提前调用语义不变。
     */
    private void formMatch(Session session, Matchmaking.Grouped group) {
        Table table = newTable(GameTypes.TableKind.MATCH, group.key().capacity(),
            Ruleset.PRESETS.get(group.key().preset()), false, group.key().preset());
        settleQueueIntoTable(group, table.roomCode());
        joinTable(table, group.playerIds(), group.botSeats(), group.key().preset());
    }

    // ============================================================ 大厅列表（spec §20.6）

    /** 专区快照：同容量且 listing() 非空的桌，在座多者在前、同数新建者在前，截 50。 */
    private List<GameTypes.RoomListEntry> roomSnapshot(int capacity) {
        List<GameTypes.RoomListEntry> entries = new ArrayList<>();
        for (Table table : tables.values()) {
            if (table.capacity() != capacity) continue;
            GameTypes.RoomListEntry e = table.listing();
            if (e != null) entries.add(e);
        }
        entries.sort(Comparator.comparingInt(GameTypes.RoomListEntry::seated).reversed()
            .thenComparing(Comparator.comparingLong(GameTypes.RoomListEntry::createdAt).reversed()));
        return entries.size() > ROOM_LIST_MAX ? List.copyOf(entries.subList(0, ROOM_LIST_MAX)) : entries;
    }

    /**
     * 合并推送：脏专区距上次推送 ≥ 1s 才检查内容；内容没变不算脏（直接清掉），
     * 变了才推送并记时刻；没到间隔保持脏，下次再试。只推给该容量的订阅者。
     */
    private void pushRoomLists(long now) {
        if (roomDirty.isEmpty()) return;
        for (int capacity : List.copyOf(roomDirty)) {
            HubOutbound.RoomLast prev = roomLast.get(capacity);
            if (prev != null && now - prev.at() < ROOM_LIST_MIN_INTERVAL_MS) continue;   // 保持脏，下次重试
            List<GameTypes.RoomListEntry> entries = roomSnapshot(capacity);
            String json = HubOutbound.roomListEntries(mapper, entries).toString();
            roomDirty.remove(capacity);
            if (prev != null && prev.json().equals(json)) continue;
            roomLast.put(capacity, new HubOutbound.RoomLast(json, now));
            for (Map.Entry<String, Integer> sub : roomSubs.entrySet()) {
                if (sub.getValue() != capacity) continue;
                Session session = sessions.get(sub.getKey());
                if (session != null) {
                    send(session, GameEvt.ROOM_LIST, null,
                        HubOutbound.roomListNode(mapper, capacity, HubOutbound.roomListEntries(mapper, entries)));
                }
            }
        }
    }

    /** 进入桌或队列即视为离开大厅：退订该会话（列表页已不在前台）。 */
    private void dropRoomSub(String clientId) {
        roomSubs.remove(clientId);
    }

    // ============================================================ tick（spec §4，顺序有意义）

    /** 无参 tick：时钟取注入的 nowMs（驱动方 200ms 一次，见 design.md）。 */
    public void tick() {
        tick(nowMs.getAsLong());
    }

    /**
     * tick 循环，顺序不可换（spec §4）：跨季 → 逐桌快照遍历派发 tick →
     * 匹配推进（成组同 queueJoin 交接）→ 大厅列表合并推送。
     */
    public void tick(long now) {
        resetSeasons(now);
        for (Table table : List.copyOf(tables.values())) {
            dispatchTable(table, table.tick(now));
        }
        Matchmaking.TickResult mt = matchmaking.tick(now);
        for (QueueOutbound o : mt.out()) deliverQueue(o);
        for (Matchmaking.Grouped g : mt.groups()) formMatch(null, g);
        pushRoomLists(now);
    }

    /**
     * 跨季处理（spec §21.3，TS 语义的 WS 半边）：先让 {@link SeasonResetHook} 做 DB 侧翻页
     * （生产实现 = {@code gameSeasonService::sweep}，每 tick 一次、批量 500），随后给赛季号
     * 翻篇的在线者推新 profile + rankChanged(0,'season-reset')，让段位卡自己刷新——
     * 段位降档与 {@code season-grant:{season}} 发币都在跑批侧，Hub 只负责通知。
     * 钩子为 null = 整体跳过（并行重构未接线时的安全缺省）。
     */
    private void resetSeasons(long now) {
        if (seasonResetHook == null) return;
        seasonResetHook.sweep(now, 500);
        int season = Rank.seasonNumber(now);
        for (Map.Entry<String, String> e : List.copyOf(sessionByPlayer.entrySet())) {
            String playerId = e.getKey();
            Integer last = seenSeason.put(playerId, season);
            if (last == null || last >= season) continue;
            Session session = sessions.get(e.getValue());
            if (session == null) continue;
            GameProfileService.ProfileView view = profiles.profile(session.userId, nicknameOf(playerId), now);
            sendToPlayer(playerId, GameEvt.PROFILE_NOW, null, HubOutbound.profileNode(mapper, view));
            int tier = view.rank() == null ? 0 : view.rank().tier();
            int stars = view.rank() == null ? 0 : view.rank().stars();
            int lossStreak = view.rank() == null ? 0 : view.rank().lossStreak();
            sendToPlayer(playerId, GameEvt.RANK_CHANGED, null,
                HubOutbound.rankChangedNode(mapper, 0, tier, stars, lossStreak, "season-reset"));
        }
    }

    // ============================================================ 优雅停机（spec §6.13）

    /**
     * 停机：把在付的全部门票清退——排队中的走 refundTicket，已记桌的按入座名单退
     * （与 sync() 关桌兜底同一路径）；然后逐个关连接。幂等：退过的票 Map 里已删，
     * 重复调用是 no-op。在途对局不恢复（§九 既定）；档案是 DB 同步落库，无需额外 flush。
     */
    public void shutdown() {
        for (String playerId : List.copyOf(ticketQueue.keySet())) refundTicket(playerId);
        for (String roomCode : List.copyOf(ticketByTable.keySet())) {
            HubOutbound.Booked booked = ticketByTable.remove(roomCode);
            if (booked == null) continue;
            for (String id : booked.ids()) creditTicketRefund(id, booked.ticket());
        }
        for (Session session : List.copyOf(sessions.values())) session.conn.close();
    }

    // ============================================================ 小工具

    /** 昵称口径（Task 2 裁定）：先清洗，再查屏蔽，命中即回退——服务端是唯一防线。 */
    private static String acceptedNickname(Object input, String fallback) {
        String name = Nickname.sanitizeNickname(input, fallback);
        return Nickname.isNicknameAllowed(name) ? name : fallback;
    }

    private static Integer capacity(JsonNode data) {
        JsonNode n = data.get("capacity");
        if (n == null || !n.isInt() || n.asInt() < 2 || n.asInt() > 4) return null;
        return n.asInt();
    }

    /** 档位名解析：wire 上小写（"standard"），枚举大写；非法返回 null。 */
    private static Ruleset.PresetId preset(JsonNode node) {
        if (node == null || !node.isTextual()) return null;
        try {
            return Ruleset.PresetId.valueOf(node.textValue().trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    private static Coins.TicketId presetTicket(JsonNode node) {
        if (node == null || !node.isTextual()) return null;
        try {
            return Coins.TicketId.valueOf(node.textValue().trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    /** data.rules（或 data 本身即规则形）→ 校验后的 RuleSet；非法返回 null。 */
    private static Ruleset.RuleSet rulesFrom(JsonNode node) {
        JsonNode rules = node.has("rules") ? node.get("rules") : node;
        if (!rules.isObject()) return null;
        JsonNode board = rules.get("boardSize"), planes = rules.get("planeCount"),
            turn = rules.get("turnSeconds"), hint = rules.get("hintAllowed");
        boolean shapeOk = board != null && board.isIntegralNumber()
            && planes != null && planes.isIntegralNumber()
            && turn != null && turn.isIntegralNumber()
            && hint != null && hint.isBoolean();
        Ruleset.ValidateResult r = Ruleset.validateRuleSet(
            shapeOk ? board.asInt() : null,
            shapeOk ? planes.asInt() : null,
            shapeOk ? turn.asInt() : null,
            hint != null && hint.isBoolean() ? hint.asBoolean() : null,
            shapeOk);
        return r.ok() ? r.rules() : null;
    }

    private static List<Rules.Cell> cells(JsonNode planes) {
        if (planes == null || !planes.isArray() || planes.isEmpty()) return null;
        List<Rules.Cell> cells = new ArrayList<>(planes.size());
        for (JsonNode p : planes) {
            JsonNode row = p.get("row"), col = p.get("col");
            if (row == null || !row.isIntegralNumber() || col == null || !col.isIntegralNumber()) return null;
            cells.add(new Rules.Cell(row.asInt(), col.asInt()));
        }
        return cells;
    }

    /**
     * room.kick 的目标解析。有意差异：protocol.md 的 room.kick data 是 seat（座位号），
     * TS 用 playerId——两种写法都收，seat 按座位表换算成真人 playerId（bot/空位拒绝）。
     */
    private static String kickTarget(Table table, JsonNode data) {
        JsonNode pid = data.get("playerId");
        if (pid != null && pid.isTextual()) return pid.textValue();
        JsonNode seat = data.get("seat");
        if (seat != null && seat.isInt()) {
            for (GameTypes.SeatView s : table.view().seats()) {
                if (s != null && s.seat() == seat.asInt()) return s.playerId();
            }
        }
        return null;
    }

    // 包内可见：测试与装配层观察内部状态（不作为公开 API 的一部分）
    Table peekTable(String roomCode) { return tables.get(roomCode); }
    String peekRoomOf(String playerId) { return tableByPlayer.get(playerId); }
}
