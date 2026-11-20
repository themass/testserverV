package com.timeline.game.engine;

import com.timeline.game.domain.GameTypes;
import com.timeline.game.domain.Rules;
import com.timeline.game.domain.Ruleset;
import com.timeline.game.protocol.GameErrorCode;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * 3–4 人混战引擎（TS apps/server/src/melee-engine.ts 直译；spec §19.6）：
 * 同时制回合、一炮打所有存活对手、结果按人私有。
 *
 * 设计约束同 DuelEngine：不持有 socket、不调用 System.currentTimeMillis()、不直接调 Math.random()。
 * 本引擎从不发 state / tableState / roomClosed（属于 Table / Hub）。
 *
 * 信息可见性（Review Focus #1）：
 * - 公开：谁已提交（submitted，无坐标）、每人被击落几架、谁出局；
 * - 私有：自己的每一炮在每个对手棋盘上的结果、别人打在自己棋盘上的炮；
 * - 无人可见：别人打别人的结果。
 */
public final class MeleeEngine implements Engine {

    /** 连续这么多轮在线未提交 → 判定挂机出局（spec §19.6）。 */
    static final int IDLE_LIMIT = 3;

    /** 把摆放的机头数组转成带 id 的 Plane，供 resolveShot 使用。 */
    private static List<Rules.Plane> toPlaneRefs(List<Rules.Cell> heads) {
        List<Rules.Plane> out = new ArrayList<>(heads.size());
        for (int i = 0; i < heads.size(); i++) out.add(new Rules.Plane("p" + i, heads.get(i)));
        return out;
    }

    // 包内可见：rankPlayers 的确定性单测需要直接构造玩家状态
    static final class PlayerState {
        final String playerId;
        final Set<String> destroyed = new LinkedHashSet<>();       // 被击落的飞机 id
        final List<GameTypes.TargetShot> shots = new ArrayList<>(); // 我打出去的炮（每炮对每个对手一条）
        final Set<String> shotKeys = new HashSet<>();              // 我打过的格子
        final List<GameTypes.IncomingShot> incoming = new ArrayList<>(); // 打在我棋盘上的炮
        int hits;                                                  // 命中别人机身 + 机头的格数（跨所有对手累加）
        boolean connected = true;
        Long disconnectedAt;                                       // 掉线时刻；在线时为 null。满 DISCONNECT_GRACE_MS 出局
        int idleStreak;                                            // 连续在线未提交的轮数；掉线期间不累计，达 IDLE_LIMIT 出局
        Rules.Cell pending;                                        // 本轮已提交的坐标；未提交为 null
        Integer eliminatedRound;                                   // 出局轮次；存活为 null
        boolean midRound;                                          // 回合中途出局：排名在同轮结算出局者之后（评审 I3）

        PlayerState(String playerId) { this.playerId = playerId; }
    }

    /**
     * 排名（spec §19.6）：存活者最前，其余按出局轮次降序；同轮按累计命中降序；
     * 仍相同 → 并列，名次跳号（1,1,3）。同名次者保持输入顺序。
     * 同一轮内，回合中途出局（midRound）者排在本轮结算时出局者之后（评审 I3）。
     */
    static List<GameTypes.RankEntry> rankPlayers(List<PlayerState> players) {
        Comparator<PlayerState> cmp = Comparator
            .comparingDouble(MeleeEngine::roundKey).reversed()
            .thenComparing(p -> -p.hits);
        // List.sort 是稳定排序：cmp 相等即保持输入顺序（TS 用原始下标做 tie-break，等价）
        List<PlayerState> sorted = new ArrayList<>(players);
        sorted.sort(cmp);
        List<GameTypes.RankEntry> out = new ArrayList<>();
        for (int i = 0; i < sorted.size(); i++) {
            PlayerState p = sorted.get(i);
            int rank;
            if (i > 0 && cmp.compare(sorted.get(i - 1), p) == 0) rank = out.get(i - 1).rank();
            else rank = i + 1;
            out.add(new GameTypes.RankEntry(p.playerId, rank, p.eliminatedRound, p.hits));
        }
        return out;
    }

    private static double roundKey(PlayerState p) {
        if (p.eliminatedRound == null) return Double.POSITIVE_INFINITY;
        return p.eliminatedRound - (p.midRound ? 0.5 : 0);
    }

    private final Ruleset.RuleSet rules;
    private final List<String> playerIds;
    private final Map<String, PlayerState> players = new LinkedHashMap<>();
    private final Engine.PlacingPhase placing;
    private GameTypes.GamePhase phase = GameTypes.GamePhase.PLACING;
    private GameTypes.GameResult result = null;
    /** 当前轮次；摆放阶段为 0。 */
    private int round = 0;
    private Long roundDeadlineAt = null;
    /** 回合中途出局（离开 / 掉线超时）的玩家，在下一条 roundResult.eliminated 里公开。 */
    private List<String> midRoundEliminated = new ArrayList<>();

    public MeleeEngine(EngineOptions opts) {
        int n = opts.playerIds().size();
        if (n < 3 || n > 4) throw new IllegalArgumentException("MeleeEngine needs 3-4 players, got " + n);
        this.rules = opts.rules();
        this.playerIds = List.copyOf(opts.playerIds());
        for (String id : playerIds) players.put(id, new PlayerState(id));
        this.placing = new Engine.PlacingPhase(rules, playerIds, opts.now(), opts.rng());
    }

    @Override public GameTypes.Mode mode() { return GameTypes.Mode.MELEE; }
    @Override public GameTypes.GamePhase phase() { return phase; }
    @Override public GameTypes.GameResult result() { return result; }

    private Long deadlineAt() {
        if (phase == GameTypes.GamePhase.PLACING) return placing.deadlineAt();
        if (phase == GameTypes.GamePhase.PLAYING) return roundDeadlineAt;
        return null;
    }

    private Outbound error(String to, GameErrorCode code, String message) {
        return new Outbound(to, new EngineEvent.Error(code, message == null ? code.name() : message));
    }

    private Outbound error(String to, GameErrorCode code) { return error(to, code, null); }

    private List<Outbound> broadcast(EngineEvent msg) {
        List<Outbound> out = new ArrayList<>(playerIds.size());
        for (String to : playerIds) out.add(new Outbound(to, msg));
        return out;
    }

    private List<PlayerState> alivePlayers() {
        return players.values().stream().filter(p -> p.eliminatedRound == null).toList();
    }

    private List<Outbound> others(String playerId, EngineEvent msg) {
        List<Outbound> out = new ArrayList<>(playerIds.size() - 1);
        for (String to : playerIds) if (!to.equals(playerId)) out.add(new Outbound(to, msg));
        return out;
    }

    // ---------------------------------------------------------------- handle

    @Override
    public List<Outbound> handle(String playerId, GameCommand cmd, long now) {
        PlayerState player = players.get(playerId);
        if (player == null || phase == GameTypes.GamePhase.FINISHED) return List.of();

        if (cmd instanceof GameCommand.Leave) {
            return player.eliminatedRound == null ? eliminateNow(player, now) : List.of();
        }
        if (player.eliminatedRound != null) return List.of(error(playerId, GameErrorCode.WRONG_PHASE, "你已出局"));

        if (phase == GameTypes.GamePhase.PLACING) {
            if (!(cmd instanceof GameCommand.Place place)) {
                return List.of(error(playerId, GameErrorCode.WRONG_PHASE, "当前是摆放阶段"));
            }
            List<Outbound> out = new ArrayList<>(placing.place(playerId, place.planes()));
            if (allAlivePlaced()) out.addAll(startRound(now));
            return out;
        }

        if (!(cmd instanceof GameCommand.Fire fire)) return List.of(error(playerId, GameErrorCode.WRONG_PHASE, "当前不能执行该操作"));
        return submit(player, fire.row(), fire.col(), now);
    }

    private List<Outbound> submit(PlayerState player, int row, int col, long now) {
        String id = player.playerId;
        if (player.pending != null) return List.of(error(id, GameErrorCode.NOT_YOUR_TURN, "本轮你已开过炮"));
        int size = rules.boardSize();
        if (row < 0 || row >= size || col < 0 || col >= size) {
            return List.of(error(id, GameErrorCode.OUT_OF_RANGE));
        }
        Rules.Cell cell = new Rules.Cell(row, col);
        if (player.shotKeys.contains(cell.key())) return List.of(error(id, GameErrorCode.REPEAT_SHOT));

        player.pending = cell;
        List<Outbound> out = new ArrayList<>(broadcast(new EngineEvent.Submitted(id, round)));
        out.addAll(resolveIfAllSubmitted(now));
        return out;
    }

    private boolean allAlivePlaced() {
        return alivePlayers().stream().allMatch(p -> placing.planesOf(p.playerId) != null);
    }

    /** 所有在线存活者都已提交 → 不等到时、不等掉线者，立即结算。无人在线时只能等到时。 */
    private List<Outbound> resolveIfAllSubmitted(long now) {
        if (phase != GameTypes.GamePhase.PLAYING) return List.of();
        List<PlayerState> online = alivePlayers().stream().filter(p -> p.connected).toList();
        if (online.isEmpty() || online.stream().anyMatch(p -> p.pending == null)) return List.of();
        return resolveRound(now);
    }

    /**
     * 离开 / 掉线超时：当场出局（记为当前轮次，排名在同轮结算出局者之后）。
     * 本轮已提交的那一炮保留，在本轮结算时作为射手结算（评审 I2）。
     * 只剩 ≤ 1 人 → gameOver；否则可能触发开局或结算。
     */
    private List<Outbound> eliminateNow(PlayerState player, long now) {
        player.eliminatedRound = round;
        player.midRound = true;
        midRoundEliminated.add(player.playerId);
        // 当场公开（评审 M2）：谁出局本就是公开信息，不必等到本轮结算；结算里照旧列出
        List<Outbound> out = new ArrayList<>(broadcast(new EngineEvent.PlayerOut(player.playerId, round)));
        if (alivePlayers().size() <= 1) { out.addAll(finish()); return out; }
        if (phase == GameTypes.GamePhase.PLACING) return allAlivePlaced() ? append(out, startRound(now)) : out;
        out.addAll(resolveIfAllSubmitted(now));
        return out;
    }

    private static List<Outbound> append(List<Outbound> base, List<Outbound> more) {
        List<Outbound> out = new ArrayList<>(base);
        out.addAll(more);
        return out;
    }

    // ---------------------------------------------------------------- 回合

    private List<Outbound> startRound(long now) {
        phase = GameTypes.GamePhase.PLAYING;
        round++;
        roundDeadlineAt = now + rules.turnSeconds() * 1000L;
        for (PlayerState p : players.values()) {
            p.pending = null;
            // 摆放阶段掉线的宽限从第 1 轮起算（评审 M3），否则摆放时长（≥45 秒）就先耗光 30 秒宽限
            if (round == 1 && p.disconnectedAt != null && p.eliminatedRound == null) p.disconnectedAt = now;
        }
        return broadcast(new EngineEvent.PhaseChanged(GameTypes.GamePhase.PLAYING, roundDeadlineAt, null, round));
    }

    /** 结算本轮：每个已提交射手（含本轮中途出局者）的那一炮落在每个存活对手棋盘上。 */
    private List<Outbound> resolveRound(long now) {
        List<PlayerState> targets = alivePlayers();
        List<PlayerState> leftShooters = midRoundEliminated.stream()
            .map(players::get).filter(p -> p.pending != null).toList();
        List<PlayerState> shooters = new ArrayList<>();
        for (PlayerState p : targets) if (p.pending != null) shooters.add(p);
        shooters.addAll(leftShooters);
        Map<String, List<GameTypes.TargetShot>> roundShots = new LinkedHashMap<>();
        Map<String, List<GameTypes.IncomingShot>> roundIncoming = new LinkedHashMap<>();
        Map<String, Integer> before = new LinkedHashMap<>();
        for (PlayerState p : targets) before.put(p.playerId, p.destroyed.size());

        for (PlayerState s : shooters) {
            Rules.Cell cell = s.pending;
            s.shotKeys.add(cell.key());
            for (PlayerState t : targets) {
                if (t == s) continue;
                List<Rules.Cell> heads = placing.planesOf(t.playerId);
                Rules.ShotResolution r = Rules.resolveShot(toPlaneRefs(heads == null ? List.of() : heads), cell);
                String planeId = r.result() == Rules.ShotResult.MISS ? "p0" : r.planeId();
                GameTypes.TargetShot shot = new GameTypes.TargetShot(t.playerId, cell.row(), cell.col(), r.result(), planeId);
                GameTypes.IncomingShot inc = new GameTypes.IncomingShot(s.playerId, cell.row(), cell.col(), r.result(), planeId);
                s.shots.add(shot);
                t.incoming.add(inc);
                push(roundShots, s.playerId, shot);
                push(roundIncoming, t.playerId, inc);
                if (r.result() != Rules.ShotResult.MISS) s.hits++;
                if (r.result() == Rules.ShotResult.HEAD) t.destroyed.add(planeId);
            }
        }

        // 挂机计数：提交清零；在线未提交 +1；掉线期间不变
        for (PlayerState p : targets) {
            if (p.pending != null) p.idleStreak = 0;
            else if (p.connected) p.idleStreak++;
        }

        List<String> eliminated = midRoundEliminated;
        midRoundEliminated = new ArrayList<>();
        for (PlayerState p : targets) {
            if (p.destroyed.size() >= rules.planeCount() || p.idleStreak >= IDLE_LIMIT) {
                p.eliminatedRound = round;
                eliminated.add(p.playerId);
            }
        }

        List<EngineEvent.DestroyedCount> destroyed = targets.stream()
            .filter(p -> p.destroyed.size() != before.get(p.playerId))
            .map(p -> new EngineEvent.DestroyedCount(p.playerId, p.destroyed.size()))
            .toList();

        List<Outbound> out = new ArrayList<>(playerIds.size());
        for (String to : playerIds) {
            out.add(new Outbound(to, new EngineEvent.RoundResult(round,
                roundShots.getOrDefault(to, List.of()), roundIncoming.getOrDefault(to, List.of()),
                destroyed, List.copyOf(eliminated))));
        }
        out.addAll(alivePlayers().size() <= 1 ? finish() : startRound(now));
        return out;
    }

    /** 存活 ≤ 1 人：结束并广播排名。 */
    private List<Outbound> finish() {
        phase = GameTypes.GamePhase.FINISHED;
        roundDeadlineAt = null;
        midRoundEliminated = new ArrayList<>();
        result = new GameTypes.GameResult(GameTypes.GameOverReason.LAST_STANDING, rankPlayers(new ArrayList<>(players.values())));
        return broadcast(new EngineEvent.GameOver(result));
    }

    // ---------------------------------------------------------------- tick / 连接

    /** 推进计时：先判掉线超时出局，再处理摆放 / 回合到时。不暂停。 */
    @Override
    public List<Outbound> tick(long now) {
        List<Outbound> out = new ArrayList<>();
        // 摆放阶段不因掉线出局（评审 M3）：掉线者到时照样被自动摆放，宽限从第 1 轮起算
        if (phase != GameTypes.GamePhase.PLACING) {
            for (PlayerState p : alivePlayers()) {
                if (phase == GameTypes.GamePhase.FINISHED) break;
                if (p.disconnectedAt != null && now - p.disconnectedAt >= DISCONNECT_GRACE_MS) out.addAll(eliminateNow(p, now));
            }
        }

        if (phase == GameTypes.GamePhase.PLACING && now >= placing.deadlineAt()) {
            // 摆放超时：为未摆放者随机落子（含掉线者），不判负
            out.addAll(placing.autoPlaceMissing());
            out.addAll(startRound(now));
        } else if (phase == GameTypes.GamePhase.PLAYING && roundDeadlineAt != null && now >= roundDeadlineAt) {
            out.addAll(resolveRound(now));
        }
        return out;
    }

    /**
     * 掉线：通知其他人 presence，不暂停；若因此在线存活者已全部提交 → 立即结算。
     * 重连：通知 presence（快照由 Table 发送）；宽限已过但 tick 还没判 → 当场出局。
     */
    @Override
    public List<Outbound> setConnected(String playerId, boolean connected, long now) {
        PlayerState player = players.get(playerId);
        if (player == null || player.connected == connected) return List.of();
        Long droppedAt = player.disconnectedAt;
        player.connected = connected;
        player.disconnectedAt = connected ? null : now;
        if (phase == GameTypes.GamePhase.FINISHED) return List.of();

        List<Outbound> out = new ArrayList<>(others(playerId, new EngineEvent.Presence(playerId, connected)));
        if (player.eliminatedRound != null) return out;
        if (!connected) {
            out.addAll(resolveIfAllSubmitted(now));
        } else if (phase != GameTypes.GamePhase.PLACING && droppedAt != null && now - droppedAt >= DISCONNECT_GRACE_MS) {
            // 摆放阶段不判出局（评审 M3）
            out.addAll(eliminateNow(player, now));
        }
        return out;
    }

    // ---------------------------------------------------------------- 视图

    @Override
    public GameTypes.GameView view(String playerId) {
        PlayerState you = players.get(playerId);
        if (you == null) throw new IllegalArgumentException("player " + playerId + " 不在本局");
        List<Rules.Cell> myPlanes = placing.planesOf(playerId);
        List<GameTypes.OtherPlayerView> others = new ArrayList<>();
        for (String id : playerIds) {
            if (id.equals(playerId)) continue;
            PlayerState p = players.get(id);
            others.add(new GameTypes.OtherPlayerView(id, p.connected, p.eliminatedRound == null,
                p.destroyed.size(), phase == GameTypes.GamePhase.PLAYING && p.pending != null));
        }
        return new GameTypes.GameView(
            GameTypes.Mode.MELEE, phase, deadlineAt(), null, round > 0 ? round : null,
            new GameTypes.YouView(
                myPlanes == null ? List.of() : List.copyOf(myPlanes),
                you.destroyed.size(), you.eliminatedRound == null,
                List.copyOf(you.shots), List.copyOf(you.incoming),
                phase == GameTypes.GamePhase.PLAYING && you.pending != null, you.pending),
            List.copyOf(others));
    }

    private static <T> void push(Map<String, List<T>> map, String key, T v) {
        map.computeIfAbsent(key, k -> new ArrayList<>()).add(v);
    }
}
