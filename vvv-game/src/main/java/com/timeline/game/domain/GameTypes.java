package com.timeline.game.domain;

import java.util.List;

/**
 * 对局视图与结果类型（TS packages/shared/src/types.ts 的引擎相关部分直译）。
 *
 * 硬约束（spec §八）：对方飞机的机头坐标任何时刻都不得下发到对手——
 * 因此所有"对手视角"类型（OtherPlayerView）里不允许出现 planes。
 */
public final class GameTypes {

    private GameTypes() {}

    public enum Mode { DUEL, MELEE }

    public enum GamePhase { PLACING, PLAYING, PAUSED, FINISHED }

    /** 摆放超时自动落子、不判负，因此没有 placementTimeout。 */
    public enum GameOverReason { HEAD, ALL_PLANES, FORFEIT, LAST_STANDING }

    /** 我打出去的一炮（对某对手棋盘）。 */
    public record TargetShot(String targetId, int row, int col, Rules.ShotResult result, String planeId) {}

    /** 打在我棋盘上的一炮。 */
    public record IncomingShot(String by, int row, int col, Rules.ShotResult result, String planeId) {}

    public record RankEntry(String playerId, int rank, Integer eliminatedRound, int hits) {}

    public record GameResult(GameOverReason reason, List<RankEntry> ranking) {}

    /** 我方视角。 */
    public record YouView(List<Rules.Cell> planes, int planesDestroyed, boolean alive,
                          List<TargetShot> shots, List<IncomingShot> incoming,
                          boolean submitted, Rules.Cell pendingShot) {}

    /** 他人视角：刻意没有 planes（隐私红线）。 */
    public record OtherPlayerView(String playerId, boolean connected, boolean alive,
                                  int planesDestroyed, boolean submitted) {}

    /**
     * 引擎对单个玩家渲染的对局快照。
     * turn：duel 当前开炮者；melee 为 null。round：melee 当前轮次（1 起）；duel 为 null。
     */
    public record GameView(GameTypes.Mode mode, GameTypes.GamePhase phase, Long deadlineAt,
                           String turn, Integer round,
                           YouView you, List<OtherPlayerView> others) {}
}
