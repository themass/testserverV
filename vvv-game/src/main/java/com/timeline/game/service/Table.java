package com.timeline.game.service;

import com.timeline.game.domain.GameTypes;
import com.timeline.game.domain.Nickname;
import com.timeline.game.domain.Ruleset;
import com.timeline.game.engine.Engine;
import com.timeline.game.engine.EngineEvent;
import com.timeline.game.engine.Outbound;
import com.timeline.game.protocol.GameErrorCode;

import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.function.BiFunction;
import java.util.function.DoubleSupplier;
import java.util.HashSet;

/**
 * 牌桌：座位、准备、房主、规则与续局生命周期（TS table.ts 直译；spec §2）。
 * 桌子不懂对局细节，对局由 {@link Engine} 负责；桌子只在引擎 finished 后回到 waiting。
 * 电脑也是一个座位（seat.bot 非空），由 tick 驱动；发给电脑的消息一律丢弃（spec §2 invariant）。
 *
 * <p>确定性：不读墙钟、逻辑内不取随机——一切涉及时间的方法都收 {@code long now}，
 * 随机源经 {@link Options#rng} 注入（spec §1、§6.10）。
 *
 * <p><b>有意差异（与 TS 的 state 消息，见移植报告）</b>：TS 的私有全量快照
 * {@code {to, msg:{type:'state', table, game}}} 在本项目的 sealed {@link TableEvent} 里
 * 没有对应变体（只有 TableState/Closed/Kicked/FromEngine，且 protocol.md 的 evt 词表也没有 state）。
 * 因此出站流里的 state 退化为 {@link TableEvent.TableState}（game 视图不随出站事件走）；
 * {table, game} 的完整私有快照仍由 {@link #snapshotFor(String)} 以 {@link TableSnapshot} 给出，
 * 供 Hub/网关层编码 wire 时取用——桌子内部"开局广播 = tableState×N 在前、state×N 在后"的
 * 顺序不变式（spec §6.4）原样保留。
 */
public class Table {

    /** 等候室掉线者是唯一在座者时（典型：房主切去微信发房间号），座位保留 5 分钟（裁定 R2）。 */
    public static final long FRIEND_SEAT_GRACE_MS = 300_000;
    /** 等候室里还有别人在座时，掉线者的座位保留 60 秒（裁定 R2）。 */
    public static final long MATCH_SEAT_GRACE_MS = 60_000;
    /** 电脑 playerId 前缀；人类 playerId 禁止以此开头（auth 拒），桌边界按此前缀丢弃收件人。 */
    public static final String BOT_ID_PREFIX = "bot:";

    /** 建桌参数（TS TableOptions 直译）。列了 null 的组件都可缺省。 */
    public record Options(
            String roomCode,
            GameTypes.TableKind kind,
            int capacity,
            Ruleset.RuleSet rules,
            long now,
            /** 是否公开到大厅列表（spec §2.6 列表投影）；只有好友房可以公开，默认 false */
            boolean listed,
            /** 列表用的不透明 id；null 则随机生成（16 位十六进制） */
            String tableId,
            /** 电脑的工厂：difficulty 预设名 + 座位号 → GameBot；null = 不允许加电脑（好友/匹配桌） */
            BiFunction<String, Integer, GameBot> botFactory,
            /** 传给引擎与电脑的随机源（先手、自动摆放、思考时间）；null 走 Math.random（仅缺省路径） */
            DoubleSupplier rng,
            /** 匹配桌的规则档位（计分局档案里记录预设 id）；好友/自定义规则为 null */
            Ruleset.PresetId preset) {

        public Options(String roomCode, GameTypes.TableKind kind, int capacity,
                       Ruleset.RuleSet rules, long now) {
            this(roomCode, kind, capacity, rules, now, false, null, null, null, null);
        }

        Options withListed(boolean v) { return new Options(roomCode, kind, capacity, rules, now, v, tableId, botFactory, rng, preset); }
        Options withTableId(String v) { return new Options(roomCode, kind, capacity, rules, now, listed, v, botFactory, rng, preset); }
        Options withKind(GameTypes.TableKind v) { return new Options(roomCode, v, capacity, rules, now, listed, tableId, botFactory, rng, preset); }
        Options withCapacity(int v) { return new Options(roomCode, kind, v, rules, now, listed, tableId, botFactory, rng, preset); }
        Options withNow(long v) { return new Options(roomCode, kind, capacity, rules, v, listed, tableId, botFactory, rng, preset); }
        Options withBotFactory(BiFunction<String, Integer, GameBot> v) { return new Options(roomCode, kind, capacity, rules, now, listed, tableId, v, rng, preset); }
        Options withRng(DoubleSupplier v) { return new Options(roomCode, kind, capacity, rules, now, listed, tableId, botFactory, v, preset); }
        Options withPreset(Ruleset.PresetId v) { return new Options(roomCode, kind, capacity, rules, now, listed, tableId, botFactory, rng, v); }
    }

    /** 刚结束那局的计分信息（TS lastGame 直译；Hub 在 gameOver 后立刻读，spec §2）。 */
    public record LastGame(String id, GameTypes.Mode mode, Ruleset.PresetId preset,
                           GameTypes.TableResult result, List<String> humans) {}

    private static final class Seat {
        String playerId;
        String nickname;
        boolean ready;
        boolean connected = true;
        /** 最近一次掉线的时间；在线时为 null */
        Long disconnectedAt;
        /** 对局中已离开，座位保留到本局结束 */
        boolean left;
        /** 电脑的驱动；真人为 null */
        GameBot bot;
    }

    private final String roomCode;
    private final GameTypes.TableKind kind;
    private final int capacity;

    private Ruleset.RuleSet rules;
    /** 规则版本：每次成功 updateRules +1（spec §2 M4） */
    private int rulesVersion = 0;
    private GameTypes.TablePhase phase = GameTypes.TablePhase.WAITING;
    private boolean closed = false;
    private Engine engine = null;
    private String hostId = null;
    private GameTypes.TableResult lastResult = null;
    private int gamesPlayed = 0;
    /** 刚结束那局的稳定 id（tableId:gamesPlayed，幂等键） */
    private String lastGameId = null;
    /** 刚结束那局的引擎模式（计分档案记录 duel/melee） */
    private GameTypes.Mode lastMode = null;
    /** 刚结束那局结束时还坐在桌边的真人（随后 close 会清空座位，Hub 计分要赶在前面） */
    private List<String> lastHumans = List.of();
    /** 被房主踢出本桌的 playerId：本桌关闭前不得再加入 */
    private final Set<String> banned = new HashSet<>();
    /** 电脑 playerId 的递增序号，按本桌计 */
    private int botSeq = 0;
    /** 本局电脑的 playerId（开局时快照），关桌后进 lastResult.botIds */
    private List<String> botIds = List.of();
    /** 大厅列表用的不透明 id：不含房间号，也不含 playerId */
    private final String tableId;
    /** 匹配桌的规则档位；好友/自定义规则为 null */
    private final Ruleset.PresetId preset;
    /** 是否公开到大厅列表；匹配房与练习房恒为 false */
    private boolean listed;
    /** 建桌时刻，列表条目用于排序 */
    private final long createdAt;
    private final Seat[] seats;
    private final BiFunction<String, Integer, GameBot> botFactory;
    private final DoubleSupplier rng;
    /** 最近一次 startGame 的建引擎参数；TS 测试靠 engineFactory 捕获，Java 无注入，故在此留档（包内测试可见）。 */
    Engine.EngineOptions lastEngineOptions;

    public Table(Options opts) {
        this.roomCode = opts.roomCode();
        this.kind = opts.kind();
        this.capacity = opts.capacity();
        this.rules = opts.rules(); // RuleSet 是不可变 record，无需再拷贝
        this.seats = new Seat[opts.capacity()];
        this.botFactory = opts.botFactory();
        this.rng = opts.rng();
        this.tableId = opts.tableId() != null ? opts.tableId() : randomTableId();
        this.preset = opts.preset();
        // 只有好友房可以公开
        this.listed = opts.listed() && opts.kind() == GameTypes.TableKind.FRIEND;
        this.createdAt = opts.now();
    }

    private static final SecureRandom ID_RANDOM = new SecureRandom();

    private static String randomTableId() {
        byte[] bytes = new byte[8];
        ID_RANDOM.nextBytes(bytes);
        return HexFormat.of().formatHex(bytes);
    }

    // ---------------------------------------------------------------- 访问器

    public String roomCode() { return roomCode; }
    public GameTypes.TableKind kind() { return kind; }
    public int capacity() { return capacity; }
    public Ruleset.RuleSet rules() { return rules; }
    public int rulesVersion() { return rulesVersion; }
    public boolean listed() { return listed; }
    public GameTypes.TablePhase phase() { return phase; }
    public boolean closed() { return closed; }
    public String tableId() { return tableId; }
    public Ruleset.PresetId preset() { return preset; }
    /** TS 的 get engine：测试与 Hub 只读取用，不得越过桌子直接驱动生命周期之外的东西。 */
    public Engine engine() { return engine; }

    /** 占着座位的 playerId（对局中已离开但座位未释放者也在内）。 */
    public List<String> members() {
        List<String> out = new ArrayList<>();
        for (Seat s : seated()) out.add(s.playerId);
        return out;
    }

    /**
     * 还在桌上的真人（电脑不算；对局中已离开、座位未释放的也不算）。
     * 与 members 不同：电脑不参与"有人"的判断。
     */
    public List<String> humanMembers() {
        List<String> out = new ArrayList<>();
        for (Seat s : seated()) if (!s.left && s.bot == null) out.add(s.playerId);
        return out;
    }

    /** 桌上还有没有真人；没有就该关桌，不让电脑之间空转。 */
    public boolean hasHumans() {
        return !humanMembers().isEmpty();
    }

    /** 刚结束那局的计分信息（Hub 在 gameOver 后立刻读；无结果为 null）。 */
    public LastGame lastGame() {
        if (lastResult == null || lastGameId == null || lastMode == null) return null;
        return new LastGame(lastGameId, lastMode, preset, lastResult, List.copyOf(lastHumans));
    }

    // ---------------------------------------------------------------- 对外方法（TS 一一对应）

    public List<TableOutbound> join(String playerId, String nickname, long now) {
        Seat existing = find(playerId);
        if (existing != null && !existing.left) return List.of(stateFor(playerId));
        GameErrorCode code = admitError(playerId);
        if (code != null) return List.of(errFor(playerId, code));

        int index = firstEmptySeat();
        Seat seat = new Seat();
        seat.playerId = playerId;
        seat.nickname = Nickname.sanitizeNickname(nickname, "玩家" + (index + 1));
        seat.ready = false;
        seat.connected = true;
        seat.disconnectedAt = null;
        seat.left = false;
        seat.bot = null;
        seats[index] = seat;
        if (kind == GameTypes.TableKind.FRIEND && hostId == null) hostId = playerId;
        return afterSeat(now);
    }

    /**
     * 外人能不能凭房间号 / 列表加入本桌（Hub 的预检用）：null = 可以。
     * 练习桌没有外来入口，被踢者在本桌关闭前不得再加入。
     */
    public GameErrorCode canJoin(String playerId) {
        if (kind == GameTypes.TableKind.PRACTICE) return GameErrorCode.ROOM_NOT_FOUND;
        return admitError(playerId);
    }

    /**
     * 补一个电脑到最小的空座：等候中且有空座才生效，否则返回 []。
     * 与 join 共用开局判定（match / practice 首局人满即开）。
     *
     * <p>座位 id 以 {@link GameBot#playerId()} 为准（GameBot 契约自带 id，TS 的
     * bot:{roomCode}:{index}:{seq} 生成规则由 bot 工厂侧负责）；昵称不经清洗、服务端直接指派。
     */
    public List<TableOutbound> addBot(Ruleset.PresetId difficulty, long now) {
        if (closed || botFactory == null) return List.of();
        if (phase != GameTypes.TablePhase.WAITING) return List.of();
        int index = firstEmptySeat();
        if (index < 0) return List.of();
        GameBot bot = botFactory.apply(difficulty.name(), index);
        botSeq++;
        Seat seat = new Seat();
        seat.playerId = bot.playerId();
        // 电脑不走 sanitizeNickname：昵称由服务端直接赋值
        seat.nickname = "电脑" + (index + 1);
        seat.ready = true;
        seat.connected = true;
        seat.disconnectedAt = null;
        seat.left = false;
        seat.bot = bot;
        seats[index] = seat;
        return afterSeat(now);
    }

    public List<TableOutbound> leave(String playerId, long now) {
        if (closed) return List.of();
        Seat seat = find(playerId);
        if (seat == null || seat.left) return List.of();
        if (phase == GameTypes.TablePhase.IN_GAME) return leaveInGame(seat, now);
        return release(seat);
    }

    /**
     * 准备 / 取消准备。带规则版本（M4）：房主改规则会 +1，
     * 携带旧版本的准备说明本人还没看过新规则，拒绝并补发本人当前状态。
     * 已准备者再发 setReady(true) 是幂等重复，照常广播。
     */
    public List<TableOutbound> setReady(String playerId, boolean ready, int rulesVersion, long now) {
        Seat seat = find(playerId);
        if (seat == null || seat.left) return List.of(err(playerId, GameErrorCode.NOT_IN_ROOM, "不在房间中"));
        if (phase != GameTypes.TablePhase.WAITING) return List.of(err(playerId, GameErrorCode.WRONG_PHASE, "对局进行中"));
        if (rulesVersion != this.rulesVersion) {
            return List.of(err(playerId, GameErrorCode.STALE_RULES, "规则已更新，请重试"), tableStateTo(playerId));
        }
        seat.ready = ready;
        if (isFull() && seated().stream().allMatch(s -> s.ready)) {
            startGame(now);
            return broadcastStart();
        }
        return broadcastTable();
    }

    public List<TableOutbound> updateRules(String playerId, Ruleset.RuleSet newRules, long now) {
        Seat seat = find(playerId);
        if (seat == null || seat.left) return List.of(err(playerId, GameErrorCode.NOT_IN_ROOM, "不在房间中"));
        // 练习房没有房主，因此谁都不能改规则
        if (kind != GameTypes.TableKind.FRIEND || !playerId.equals(hostId)) {
            return List.of(err(playerId, GameErrorCode.NOT_HOST, "只有房主可以修改规则"));
        }
        if (phase == GameTypes.TablePhase.IN_GAME) return List.of(err(playerId, GameErrorCode.ROOM_IN_GAME, "对局进行中"));
        this.rules = newRules;
        this.rulesVersion++;
        resetReady();
        return broadcastTable();
    }

    /**
     * 房主踢人：仅在好友房的等候室里，踢一个未准备的真人在座者。
     * 已准备者不能踢——他就在开局倒计时的路上，桌子会自己把他带进对局（用户裁定）。
     * 被踢者收到 kicked、座位立即释放、本桌关闭前不得再加入。
     */
    public List<TableOutbound> kick(String hostId, String targetId, long now) {
        Seat actor = find(hostId);
        if (actor == null || actor.left) return List.of(err(hostId, GameErrorCode.NOT_IN_ROOM, "不在房间中"));
        // 匹配房、练习房没有房主，也就没有人可以踢
        if (kind != GameTypes.TableKind.FRIEND || !hostId.equals(this.hostId)) {
            return List.of(err(hostId, GameErrorCode.NOT_HOST, "只有房主可以踢人"));
        }
        if (phase == GameTypes.TablePhase.IN_GAME) return List.of(err(hostId, GameErrorCode.ROOM_IN_GAME, "对局进行中"));
        Seat target = find(targetId);
        if (target == null || target.left || target.playerId.equals(hostId) || target.bot != null) {
            return List.of(err(hostId, GameErrorCode.TARGET_NOT_FOUND, "目标不在房间中"));
        }
        if (target.ready) return List.of(err(hostId, GameErrorCode.TARGET_READY, "对方已准备，无法踢出"));

        banned.add(target.playerId);
        // kicked 先于释放：release 只把 tableState 发给剩下的人
        List<TableOutbound> out = new ArrayList<>();
        out.add(new TableOutbound(target.playerId, new TableEvent.Kicked(roomCode)));
        out.addAll(release(target));
        return out(out);
    }

    public List<TableOutbound> setNickname(String playerId, String nickname) {
        Seat seat = find(playerId);
        if (seat == null || seat.left) return List.of(err(playerId, GameErrorCode.NOT_IN_ROOM, "不在房间中"));
        seat.nickname = Nickname.sanitizeNickname(nickname, seat.nickname);
        return broadcastTable();
    }

    public List<TableOutbound> handleGame(String playerId, Engine.GameCommand cmd, long now) {
        Seat seat = find(playerId);
        if (seat == null || seat.left) return List.of(err(playerId, GameErrorCode.NOT_IN_ROOM, "不在房间中"));
        if (engine == null) return List.of(err(playerId, GameErrorCode.WRONG_PHASE, "对局未开始"));
        // TS 的 leaveRoom 路由：认输/离开都走桌子自己的 leave
        if (cmd instanceof Engine.GameCommand.Leave) return leave(playerId, now);
        List<TableOutbound> out = new ArrayList<>(wrap(engine.handle(playerId, cmd, now)));
        out.addAll(afterEngine(now));
        return out(out);
    }

    public List<TableOutbound> tick(long now) {
        if (closed) return List.of();
        if (engine == null) return out(releaseExpired(now));
        List<TableOutbound> out = new ArrayList<>(wrap(engine.tick(now)));
        out.addAll(afterEngine(now));
        if (engine != null) pollBots(now, out);
        return out(out);
    }

    public List<TableOutbound> setConnected(String playerId, boolean connected, long now) {
        if (closed) return List.of();
        Seat seat = find(playerId);
        // 电脑永远在线，掉线状态对它没有意义
        if (seat == null || seat.left || seat.bot != null) return List.of();
        seat.connected = connected;
        seat.disconnectedAt = connected ? null : now;
        if (engine != null) {
            List<TableOutbound> out = new ArrayList<>(wrap(engine.setConnected(playerId, connected, now)));
            List<TableOutbound> after = afterEngine(now);
            out.addAll(after);
            // 引擎结束时 afterEngine 已经广播过桌子状态
            if (engine == null) return out(out);
            out.addAll(broadcastTable());
            return out(out);
        }
        return out(broadcastTable());
    }

    public GameTypes.TableView view() {
        List<GameTypes.SeatView> seatViews = new ArrayList<>(seats.length);
        for (int i = 0; i < seats.length; i++) {
            Seat s = seats[i];
            seatViews.add(s == null ? null
                : new GameTypes.SeatView(i, s.playerId, s.nickname, s.ready, s.connected, s.bot != null));
        }
        return new GameTypes.TableView(roomCode, kind, capacity, rules, rulesVersion, listed,
            hostId, phase, seatViews, lastResult);
    }

    /**
     * 单人全量快照（TS stateFor）：{table, game} 的私有视图。
     * game 为 null 表示桌上没有在进行的对局（等待期）。
     */
    public TableSnapshot snapshotFor(String playerId) {
        return new TableSnapshot(view(), engine != null ? engine.view(playerId) : null);
    }

    /**
     * 出站形态的 state（见类注释的"有意差异"）：sealed TableEvent 没有携带 game 视图的变体，
     * 出站流里退化为 table.state；完整的 {table, game} 走 {@link #snapshotFor(String)}。
     */
    public TableOutbound stateFor(String playerId) {
        return new TableOutbound(playerId, new TableEvent.TableState(view()));
    }

    /**
     * 大厅列表的投影：只有"好友房 + 已公开 + 等候中 + 有空座"才出现。
     * 条目里没有房间号、没有 playerId、没有准备状态；电脑座位也只露 { seat, nickname }。
     */
    public GameTypes.RoomListEntry listing() {
        if (closed) return null;
        if (kind != GameTypes.TableKind.FRIEND || !listed) return null;
        if (phase != GameTypes.TablePhase.WAITING) return null;
        if (isFull()) return null;

        String hostNickname = hostId == null ? "" : seatNicknameOrEmpty(hostId);
        List<GameTypes.RoomListEntry.PublicSeat> publicSeats = new ArrayList<>(seats.length);
        for (int i = 0; i < seats.length; i++) {
            Seat s = seats[i];
            publicSeats.add(s == null ? null : new GameTypes.RoomListEntry.PublicSeat(i, s.nickname));
        }
        return new GameTypes.RoomListEntry(tableId, capacity, rules, hostNickname,
            seated().size(), publicSeats, createdAt);
    }

    /** 房主开关"公开到大厅列表"。 */
    public List<TableOutbound> setListed(String playerId, boolean listed) {
        Seat actor = find(playerId);
        if (actor == null || actor.left) return List.of(err(playerId, GameErrorCode.NOT_IN_ROOM, "不在房间中"));
        if (kind != GameTypes.TableKind.FRIEND || !playerId.equals(hostId)) {
            return List.of(err(playerId, GameErrorCode.NOT_HOST, "只有房主可以修改公开设置"));
        }
        if (phase == GameTypes.TablePhase.IN_GAME) return List.of(err(playerId, GameErrorCode.ROOM_IN_GAME, "对局进行中"));
        this.listed = listed;
        return out(broadcastTable());
    }

    // ---------------------------------------------------------------- 内部

    private List<Seat> seated() {
        List<Seat> out = new ArrayList<>();
        for (Seat s : seats) if (s != null) out.add(s);
        return out;
    }

    private List<Seat> active() {
        List<Seat> out = new ArrayList<>();
        for (Seat s : seated()) if (!s.left) out.add(s);
        return out;
    }

    private Seat find(String playerId) {
        for (Seat s : seated()) if (s.playerId.equals(playerId)) return s;
        return null;
    }

    private boolean isFull() {
        for (Seat s : seats) if (s == null) return false;
        return true;
    }

    private int firstEmptySeat() {
        for (int i = 0; i < seats.length; i++) if (seats[i] == null) return i;
        return -1;
    }

    private String seatNicknameOrEmpty(String playerId) {
        Seat s = find(playerId);
        return s == null ? "" : s.nickname;
    }

    /** 桌子层错误（引擎事件里的 Error，桌子出站统一包 FromEngine，与引擎自身错误同一条通路）。 */
    private TableOutbound err(String to, GameErrorCode code, String message) {
        return new TableOutbound(to, new TableEvent.FromEngine(new EngineEvent.Error(code, message)));
    }

    /** 加入类错误的文案；错误码本身才是协议语义，这里只是给人看的一句话。 */
    private TableOutbound errFor(String to, GameErrorCode code) {
        String message = switch (code) {
            case ROOM_NOT_FOUND -> "房间不存在";
            case BANNED -> "已被房主移出房间";
            case ROOM_IN_GAME -> "对局进行中";
            case ROOM_FULL -> "房间已满";
            default -> "无法加入房间";
        };
        return err(to, code, message);
    }

    /** 外人加入本桌的准入判定（join 与 canJoin 共用）：null = 可以加入。 */
    private GameErrorCode admitError(String playerId) {
        if (closed) return GameErrorCode.ROOM_NOT_FOUND;
        if (banned.contains(playerId)) return GameErrorCode.BANNED;
        if (phase == GameTypes.TablePhase.IN_GAME) return GameErrorCode.ROOM_IN_GAME;
        if (isFull()) return GameErrorCode.ROOM_FULL;
        return null;
    }

    /** 只发给一个人（含最新规则版本）。 */
    private TableOutbound tableStateTo(String playerId) {
        return new TableOutbound(playerId, new TableEvent.TableState(view()));
    }

    /** 丢弃发给电脑的出站消息：电脑没有 socket，也不缓存（table.ts:439 的桌边界不变式）。 */
    private List<TableOutbound> out(List<TableOutbound> out) {
        List<TableOutbound> kept = new ArrayList<>(out.size());
        for (TableOutbound o : out) {
            if (!o.to().startsWith(BOT_ID_PREFIX)) kept.add(o);
        }
        return kept;
    }

    private List<TableOutbound> wrap(List<Outbound> engineOut) {
        List<TableOutbound> out = new ArrayList<>(engineOut.size());
        for (Outbound o : engineOut) out.add(new TableOutbound(o.to(), new TableEvent.FromEngine(o.event())));
        return out;
    }

    private List<TableOutbound> broadcastTable() {
        List<TableOutbound> out = new ArrayList<>();
        for (Seat s : active()) out.add(tableStateTo(s.playerId));
        return out(out);
    }

    /** 开局：桌子状态之外，给每位在座者发含引擎视图（摆放 deadlineAt）的完整 state（顺序不变式：tableStates 在前）。 */
    private List<TableOutbound> broadcastStart() {
        List<TableOutbound> out = new ArrayList<>(broadcastTable());
        for (Seat s : active()) out.add(stateFor(s.playerId));
        return out(out);
    }

    /**
     * 裁定 R2：掉线者是唯一的真人时保留 5 分钟，否则 60 秒（只数真人，电脑不算有人等）。
     */
    private long seatGraceMs(Seat seat) {
        List<String> humans = humanMembers();
        return humans.size() == 1 && humans.get(0).equals(seat.playerId)
            ? FRIEND_SEAT_GRACE_MS
            : MATCH_SEAT_GRACE_MS;
    }

    /** 清空准备；电脑永远已准备，立即恢复。 */
    private void resetReady() {
        for (Seat s : seated()) s.ready = s.bot != null;
    }

    /** 入座之后的开局判定：match / practice 首局人满即开，否则广播。 */
    private List<TableOutbound> afterSeat(long now) {
        boolean autoStart = kind == GameTypes.TableKind.MATCH || kind == GameTypes.TableKind.PRACTICE;
        if (autoStart && gamesPlayed == 0 && isFull()) {
            startGame(now);
            return broadcastStart();
        }
        return broadcastTable();
    }

    /** 同步新建引擎，规则取开局这一刻的值。 */
    private void startGame(long now) {
        List<Seat> seatsSnapshot = seated();
        resetReady();
        this.lastResult = null;
        List<String> bots = new ArrayList<>();
        List<String> playerIds = new ArrayList<>();
        for (Seat s : seatsSnapshot) {
            playerIds.add(s.playerId);
            if (s.bot != null) bots.add(s.playerId);
        }
        this.botIds = List.copyOf(bots);
        this.phase = GameTypes.TablePhase.IN_GAME;
        Engine.EngineOptions opts = rng != null
            ? new Engine.EngineOptions(rules, List.copyOf(playerIds), now, rng)
            : new Engine.EngineOptions(rules, List.copyOf(playerIds), now);
        this.lastEngineOptions = opts;
        this.engine = Engine.create(opts);
        // 引擎默认全员在线；开局这一刻已掉线的座位要告诉它（评审 I1）。
        // 其输出不转发：紧随其后的 broadcastStart 快照已反映掉线状态。
        for (Seat s : seatsSnapshot) {
            if (!s.connected) engine.setConnected(s.playerId, false, now);
        }
    }

    /**
     * 依座位顺序让每个电脑做一次决策：输入只有 engine.view(自己) 与 rules，
     * 动作走引擎的公开入口。引擎一结束就停止本轮轮询。
     * 思考时长的钳制归 GameBot 实现自己管（poll 在未到期前返回 empty），桌子每 tick 都问一次。
     */
    private void pollBots(long now, List<TableOutbound> out) {
        for (Seat seat : seated()) {
            Engine e = this.engine;
            if (e == null || e.phase() == GameTypes.GamePhase.FINISHED) return;
            if (seat.bot == null) continue;
            Optional<Engine.GameCommand> cmd = seat.bot.poll(e.view(seat.playerId), rules, now);
            if (cmd.isEmpty()) continue;
            out.addAll(wrap(e.handle(seat.playerId, cmd.get(), now)));
            out.addAll(afterEngine(now));
        }
    }

    /** 房主离开后转给最小座位号的在座者。 */
    private void fixHost() {
        if (kind != GameTypes.TableKind.FRIEND) return;
        if (hostId != null) {
            for (Seat s : active()) if (s.playerId.equals(hostId)) return;
        }
        List<Seat> act = active();
        hostId = act.isEmpty() ? null : act.get(0).playerId;
    }

    private void clearSeat(Seat seat) {
        for (int i = 0; i < seats.length; i++) {
            if (seats[i] == seat) { seats[i] = null; return; }
        }
    }

    private List<TableOutbound> close(boolean notify) {
        List<TableOutbound> out = new ArrayList<>();
        if (notify) for (Seat s : active()) out.add(new TableOutbound(s.playerId, new TableEvent.Closed()));
        this.closed = true;
        this.hostId = null;
        this.engine = null;
        this.botIds = List.of();
        for (int i = 0; i < seats.length; i++) seats[i] = null;
        return out(out);
    }

    /** 等候中释放座位（leave 与掉线超时共用）。 */
    private List<TableOutbound> release(Seat seat) {
        clearSeat(seat);
        // 桌上没有真人就关桌，不让电脑之间空转
        if (!hasHumans()) return close(false);
        // 匹配桌打完一局不留桌：离开即散
        if (kind == GameTypes.TableKind.MATCH && gamesPlayed > 0) return close(true);
        fixHost();
        return out(broadcastTable());
    }

    private List<TableOutbound> releaseExpired(long now) {
        List<TableOutbound> out = new ArrayList<>();
        for (Seat seat : seated()) {
            if (closed) break;
            if (seat.connected || seat.disconnectedAt == null) continue;
            if (now - seat.disconnectedAt >= seatGraceMs(seat)) out.addAll(release(seat));
        }
        return out;
    }

    private List<TableOutbound> leaveInGame(Seat seat, long now) {
        List<TableOutbound> out = new ArrayList<>(
            engine != null ? wrap(engine.handle(seat.playerId, new Engine.GameCommand.Leave(), now)) : List.of());
        seat.left = true;
        fixHost();
        out.addAll(afterEngine(now));
        // 没有真人了就关桌，不广播
        if (!hasHumans()) return out(concat(out, close(false)));
        // 引擎结束时 afterEngine 已经广播过桌子状态
        if (engine != null) out.addAll(broadcastTable());
        return out(out);
    }

    private static List<TableOutbound> concat(List<TableOutbound> a, List<TableOutbound> b) {
        List<TableOutbound> out = new ArrayList<>(a);
        out.addAll(b);
        return out;
    }

    /** 引擎调用之后检查是否结束；结束则记录结果、释放离开者的座位、应用匹配房规则。 */
    private List<TableOutbound> afterEngine(long now) {
        Engine e = this.engine;
        if (e == null || e.phase() != GameTypes.GamePhase.FINISHED) return List.of();
        GameTypes.GameResult result = e.result();
        this.lastResult = result != null
            ? new GameTypes.TableResult(result.reason(), result.ranking(), botIds)
            : null;
        // 计分局档案用：id = tableId:gamesPlayed，重复 gameOver 重放不加星
        this.lastGameId = result != null ? tableId + ":" + gamesPlayed : null;
        this.lastMode = result != null ? e.mode() : null;
        this.botIds = List.of();
        // close()/release() 可能在本轮就把座位清空（match 桌有人离开即关桌），
        // 所以此刻就把还坐在桌边的真人快照下来，交给 Hub 计分
        this.lastHumans = humanMembers();
        this.engine = null;
        this.phase = GameTypes.TablePhase.WAITING;
        this.gamesPlayed++;

        boolean someoneLeft = false;
        for (Seat seat : seated()) {
            if (seat.left) {
                someoneLeft = true;
                clearSeat(seat);
            } else if (!seat.connected) {
                // 等候室的掉线宽限从本局结束时重新计时
                seat.disconnectedAt = now;
            }
        }
        // 桌上没有真人就关桌，不让电脑之间空转
        if (!hasHumans()) return close(false);
        // 关桌前先把结果发给留下的人，否则他们只收到 gameOver + roomClosed，看不到排名（评审 C1）
        if (kind == GameTypes.TableKind.MATCH && someoneLeft) {
            List<TableOutbound> out = new ArrayList<>(broadcastTable());
            out.addAll(close(true));
            return out(out);
        }
        fixHost();
        return out(broadcastTable());
    }
}