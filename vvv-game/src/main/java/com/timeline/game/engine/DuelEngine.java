package com.timeline.game.engine;

import com.timeline.game.domain.GameTypes;
import com.timeline.game.domain.Rules;
import com.timeline.game.domain.Ruleset;
import com.timeline.game.protocol.GameErrorCode;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.DoubleSupplier;

/**
 * 2 人对决引擎（TS apps/server/src/duel-engine.ts 直译；spec §二、§九、§十）。
 *
 * 设计约束：本类不持有 socket、不调用 System.currentTimeMillis()、不直接调 Math.random()。
 * 时间与随机源都从参数进来，因此「回合到点」「谁先手」这类行为可以确定性测试。
 * 座位、准备、再来一局、关房都属于 Table；引擎只管一局之内的事。
 */
public final class DuelEngine implements Engine {

    /** 把摆放的机头数组转成带 id 的 Plane，供 resolveShot 使用。 */
    private static List<Rules.Plane> toPlaneRefs(List<Rules.Cell> heads) {
        List<Rules.Plane> out = new ArrayList<>(heads.size());
        for (int i = 0; i < heads.size(); i++) out.add(new Rules.Plane("p" + i, heads.get(i)));
        return out;
    }

    private static final class PlayerState {
        final String playerId;
        final Set<String> destroyed = new LinkedHashSet<>();      // 被击落的飞机 id
        final Map<String, GameTypes.TargetShot> shots = new LinkedHashMap<>(); // 我打出去的炮，key = cellKey
        final List<GameTypes.IncomingShot> incoming = new ArrayList<>();       // 打在我棋盘上的炮
        int hits;                                                  // 命中对方机身 + 机头的格数
        boolean connected = true;
        Long disconnectedAt;                                       // 掉线时刻；在线时为 null。宽限按人独立计算（I1）

        PlayerState(String playerId) { this.playerId = playerId; }
    }

    private final Ruleset.RuleSet rules;
    private final String idA, idB;
    private final DoubleSupplier rng;
    private final Map<String, PlayerState> players = new LinkedHashMap<>();
    private final Engine.PlacingPhase placing;
    private GameTypes.GamePhase phase = GameTypes.GamePhase.PLACING;
    private GameTypes.GameResult result = null;
    private int turnIndex;
    /** playing 阶段的回合 deadline；placing 阶段以 PlacingPhase 为准。 */
    private Long turnDeadlineAt = null;
    private Long pausedAt = null;
    private GameTypes.GamePhase resumePhase = null;

    public DuelEngine(EngineOptions opts) {
        if (opts.playerIds().size() != 2) {
            throw new IllegalArgumentException("DuelEngine needs exactly 2 players, got " + opts.playerIds().size());
        }
        this.rules = opts.rules();
        this.idA = opts.playerIds().get(0);
        this.idB = opts.playerIds().get(1);
        this.rng = opts.rng();
        players.put(idA, new PlayerState(idA));
        players.put(idB, new PlayerState(idB));

        // rng 决定先手：< 0.5 取第一个玩家
        this.turnIndex = rng.getAsDouble() < 0.5 ? 0 : 1;
        this.placing = new Engine.PlacingPhase(rules, List.of(idA, idB), opts.now(), rng);
    }

    @Override public GameTypes.Mode mode() { return GameTypes.Mode.DUEL; }
    @Override public GameTypes.GamePhase phase() { return phase; }
    @Override public GameTypes.GameResult result() { return result; }

    private Long deadlineAt() {
        if (phase == GameTypes.GamePhase.PLACING) return placing.deadlineAt();
        if (phase == GameTypes.GamePhase.PLAYING) return turnDeadlineAt;
        return null;
    }

    private long turnMs() { return rules.turnSeconds() * 1000L; }

    private String otherPlayerId(String playerId) { return idA.equals(playerId) ? idB : idA; }

    private String currentTurnPlayerId() { return turnIndex == 0 ? idA : idB; }

    private Outbound error(String to, GameErrorCode code, String message) {
        return new Outbound(to, new EngineEvent.Error(code, message == null ? code.name() : message));
    }

    private Outbound error(String to, GameErrorCode code) { return error(to, code, null); }

    private List<Outbound> broadcast(EngineEvent msg) {
        return List.of(new Outbound(idA, msg), new Outbound(idB, msg));
    }

    // ---------------------------------------------------------------- handle

    /** 只处理 place / fire / leave；finished 之后一律忽略。 */
    @Override
    public List<Outbound> handle(String playerId, GameCommand cmd, long now) {
        PlayerState player = players.get(playerId);
        if (player == null || phase == GameTypes.GamePhase.FINISHED) return List.of();
        if (cmd instanceof GameCommand.Leave) return forfeit(otherPlayerId(playerId));

        return switch (phase) {
            case PLACING -> handlePlacing(player, cmd, now);
            case PLAYING -> handlePlaying(player, cmd, now);
            case PAUSED -> List.of(error(playerId, GameErrorCode.PAUSED, "对手已掉线，等待重连"));
            case FINISHED -> List.of();
        };
    }

    private List<Outbound> handlePlacing(PlayerState player, GameCommand cmd, long now) {
        if (!(cmd instanceof GameCommand.Place place)) {
            return List.of(error(player.playerId, GameErrorCode.WRONG_PHASE, "当前是摆放阶段"));
        }
        List<Outbound> out = new ArrayList<>(placing.place(player.playerId, place.planes()));
        if (placing.allPlaced()) out.addAll(startPlaying(now));
        return out;
    }

    private List<Outbound> handlePlaying(PlayerState player, GameCommand cmd, long now) {
        if (!(cmd instanceof GameCommand.Fire fire)) {
            return List.of(error(player.playerId, GameErrorCode.WRONG_PHASE, "当前不能执行该操作"));
        }
        if (!currentTurnPlayerId().equals(player.playerId)) return List.of(error(player.playerId, GameErrorCode.NOT_YOUR_TURN));

        int size = rules.boardSize();
        if (fire.row() < 0 || fire.row() >= size || fire.col() < 0 || fire.col() >= size) {
            return List.of(error(player.playerId, GameErrorCode.OUT_OF_RANGE));
        }

        Rules.Cell cell = new Rules.Cell(fire.row(), fire.col());
        if (Rules.isRepeatShot(player.shots.keySet(), cell)) return List.of(error(player.playerId, GameErrorCode.REPEAT_SHOT));

        return applyShot(player, cell, now);
    }

    private List<Outbound> startPlaying(long now) {
        phase = GameTypes.GamePhase.PLAYING;
        turnDeadlineAt = now + turnMs();
        return broadcast(new EngineEvent.PhaseChanged(GameTypes.GamePhase.PLAYING, turnDeadlineAt, currentTurnPlayerId(), null));
    }

    /** 结算一炮。正常开炮与超时代打共用此路径。 */
    private List<Outbound> applyShot(PlayerState shooter, Rules.Cell cell, long now) {
        PlayerState target = players.get(otherPlayerId(shooter.playerId));
        List<Rules.Cell> targetHeads = placing.planesOf(target.playerId);
        List<Rules.Plane> targetPlanes = toPlaneRefs(targetHeads == null ? List.of() : targetHeads);
        Rules.ShotResolution resolution = Rules.resolveShot(targetPlanes, cell);
        Rules.ShotResult shotResult = resolution.result();
        String planeId = shotResult == Rules.ShotResult.MISS ? "p0" : resolution.planeId();

        shooter.shots.put(cell.key(), new GameTypes.TargetShot(target.playerId, cell.row(), cell.col(), shotResult, planeId));
        target.incoming.add(new GameTypes.IncomingShot(shooter.playerId, cell.row(), cell.col(), shotResult, planeId));
        if (shotResult != Rules.ShotResult.MISS) shooter.hits++;
        if (shotResult == Rules.ShotResult.HEAD) target.destroyed.add(planeId);

        // 先换手（若对局未结束），再广播，这样 nextTurn 是最终值
        boolean allDestroyed = Rules.isAllPlanesDestroyed(targetPlanes, new ArrayList<>(target.destroyed));
        if (!allDestroyed) {
            turnIndex = turnIndex == 0 ? 1 : 0;
            turnDeadlineAt = now + turnMs();
        }

        List<Outbound> out = new ArrayList<>(broadcast(
            new EngineEvent.GameShot(shooter.playerId, cell.row(), cell.col(), shotResult, planeId, currentTurnPlayerId())));
        if (shotResult == Rules.ShotResult.HEAD) {
            out.addAll(broadcast(new EngineEvent.PlaneDestroyed(target.playerId, planeId)));
        }
        if (allDestroyed) {
            out.addAll(finish(shooter.playerId, rules.planeCount() == 1 ? GameTypes.GameOverReason.HEAD : GameTypes.GameOverReason.ALL_PLANES));
        }
        return out;
    }

    private List<Outbound> finish(String winnerId, GameTypes.GameOverReason reason) {
        String loserId = otherPlayerId(winnerId);
        phase = GameTypes.GamePhase.FINISHED;
        turnDeadlineAt = null;
        pausedAt = null;
        resumePhase = null;
        result = new GameTypes.GameResult(reason, List.of(
            new GameTypes.RankEntry(winnerId, 1, null, players.get(winnerId).hits),
            new GameTypes.RankEntry(loserId, 2, null, players.get(loserId).hits)));
        return broadcast(new EngineEvent.GameOver(result));
    }

    private List<Outbound> forfeit(String winnerId) {
        return finish(winnerId, GameTypes.GameOverReason.FORFEIT);
    }

    // ---------------------------------------------------------------- tick

    /** 推进计时。纯同步，时间从参数进来。 */
    @Override
    public List<Outbound> tick(long now) {
        if (phase == GameTypes.GamePhase.PAUSED) {
            String expired = firstExpiredPlayer(now);
            return expired == null ? List.of() : forfeit(otherPlayerId(expired));
        }

        if (phase == GameTypes.GamePhase.PLACING) {
            if (now < placing.deadlineAt()) return List.of();
            // 摆放超时：为未摆放者随机落子，不判负（spec §二）
            List<Outbound> out = new ArrayList<>(placing.autoPlaceMissing());
            if (placing.allPlaced()) out.addAll(startPlaying(now));
            return out;
        }

        if (phase == GameTypes.GamePhase.PLAYING) {
            if (turnDeadlineAt != null && now >= turnDeadlineAt) return autoFire(now);
        }

        return List.of();
    }

    /** 宽限已过的掉线玩家中，最早掉线的那位（双方都超时时判先掉线者负）。 */
    private String firstExpiredPlayer(long now) {
        PlayerState found = null;
        for (PlayerState p : players.values()) {
            if (p.disconnectedAt == null || now - p.disconnectedAt < DISCONNECT_GRACE_MS) continue;
            if (found == null || p.disconnectedAt < found.disconnectedAt) found = p;
        }
        return found == null ? null : found.playerId;
    }

    /** 回合超时：在对方棋盘上随机挑一个未打过的格子代打。 */
    private List<Outbound> autoFire(long now) {
        PlayerState shooter = players.get(currentTurnPlayerId());
        List<Rules.Cell> pool = Rules.unshotCells(rules.boardSize(), new HashSet<>(shooter.shots.keySet()));
        if (pool.isEmpty()) return List.of();
        Rules.Cell pick = pool.get((int) Math.floor(rng.getAsDouble() * pool.size()));
        return applyShot(shooter, pick, now);
    }

    // ---------------------------------------------------------------- 连接

    /**
     * 掉线：通知对手 presence，未暂停则进入 paused。
     * 重连：不发快照（state 由 Table 发送），宽限已过则判负，否则顺延 deadline 并恢复。
     */
    @Override
    public List<Outbound> setConnected(String playerId, boolean connected, long now) {
        PlayerState player = players.get(playerId);
        if (player == null) return List.of();
        String other = otherPlayerId(playerId);

        if (!connected) {
            if (!player.connected) return List.of();
            player.connected = false;
            player.disconnectedAt = now;
            if (phase == GameTypes.GamePhase.FINISHED) return List.of();

            List<Outbound> out = new ArrayList<>();
            out.add(new Outbound(other, new EngineEvent.Presence(playerId, false)));
            if (phase != GameTypes.GamePhase.PAUSED) {
                pausedAt = now;
                resumePhase = phase;
                phase = GameTypes.GamePhase.PAUSED;
                // 在线方也要知道进入暂停（I5/C3），否则倒计时继续走、界面不变
                out.add(new Outbound(other, new EngineEvent.PhaseChanged(GameTypes.GamePhase.PAUSED, null, null, null)));
            }
            return out;
        }

        // ---- 重连 ----
        boolean wasOffline = !player.connected;
        Long droppedAt = player.disconnectedAt;
        player.connected = true;
        player.disconnectedAt = null;

        // 已在线又来一次（半开连接后的新 socket，I2）或对局已结束：快照由 Table 补发
        if (!wasOffline || phase == GameTypes.GamePhase.FINISHED) return List.of();

        // 宽限已过但 tick 还没来得及判（C1）：在这里判掉线方负
        if (droppedAt != null && now - droppedAt >= DISCONNECT_GRACE_MS) return forfeit(other);

        List<Outbound> out = new ArrayList<>();
        out.add(new Outbound(other, new EngineEvent.Presence(playerId, true)));

        // 对方也还掉线着：保持暂停（I1）
        if (!players.get(other).connected) return out;

        if (phase == GameTypes.GamePhase.PAUSED && pausedAt != null) {
            long paused = now - pausedAt;
            GameTypes.GamePhase resume = resumePhase == null ? GameTypes.GamePhase.PLAYING : resumePhase;
            if (resume == GameTypes.GamePhase.PLACING) placing.extend(paused);
            else if (turnDeadlineAt != null) turnDeadlineAt += paused;
            phase = resume;
            pausedAt = null;
            resumePhase = null;
            if (resume == GameTypes.GamePhase.PLAYING) {
                out.addAll(broadcast(new EngineEvent.PhaseChanged(resume, deadlineAt(), currentTurnPlayerId(), null)));
            } else {
                out.addAll(broadcast(new EngineEvent.PhaseChanged(resume, deadlineAt(), null, null)));
            }
        }
        return out;
    }

    // ---------------------------------------------------------------- 视图

    @Override
    public GameTypes.GameView view(String playerId) {
        PlayerState you = players.get(playerId);
        if (you == null) throw new IllegalArgumentException("player " + playerId + " 不在本局");
        PlayerState opp = players.get(otherPlayerId(playerId));
        java.util.function.Predicate<PlayerState> alive = p -> p.destroyed.size() < rules.planeCount();

        List<Rules.Cell> myPlanes = placing.planesOf(playerId);
        return new GameTypes.GameView(
            GameTypes.Mode.DUEL, phase, deadlineAt(), currentTurnPlayerId(), null,
            new GameTypes.YouView(
                myPlanes == null ? List.of() : List.copyOf(myPlanes),
                you.destroyed.size(), alive.test(you),
                List.copyOf(you.shots.values()), List.copyOf(you.incoming),
                // 轮流制没有「本轮已提交」：一炮即结算（评审 M1）
                false, null),
            List.of(new GameTypes.OtherPlayerView(opp.playerId, opp.connected, alive.test(opp), opp.destroyed.size(), false)));
    }
}
