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

    // ---------------------------------------------------------------- 桌子层（TS types.ts 桌子相关直译）

    /** 桌子来源：好友房 / 匹配局 / 练习局（决定计费、上榜、散桌规则）。 */
    public enum TableKind { FRIEND, MATCH, PRACTICE }

    /** 桌子相位（对局的 placing/playing/... 在 GamePhase，这是外层）。 */
    public enum TablePhase { WAITING, IN_GAME }

    /** 座位视图；playerId 对好友房可见（配 roomCode 使用），匹配房客户端本来就带着它。 */
    public record SeatView(int seat, String playerId, String nickname,
                           boolean ready, boolean connected, boolean bot) {}

    /** 一局的结果 + 参与 bot 列表（TableResult：结算与"再来一局"都用它）。 */
    public record TableResult(GameOverReason reason, List<RankEntry> ranking, List<String> botIds) {}

    /**
     * 桌子全量快照（协议 evt table.state 的数据源）：客户端无脑覆盖。
     * lastResult：上一局结果；重开局或改规则后清空由桌子逻辑决定。
     */
    public record TableView(String roomCode, TableKind kind, int capacity,
                            Ruleset.RuleSet rules, int rulesVersion, boolean listed,
                            String hostId, TablePhase phase,
                            List<SeatView> seats, TableResult lastResult) {}

    /**
     * 大厅列表条目（evt room.list）：隐私红线——不含 roomCode / playerId / ready。
     * 只有 friend+listed+waiting+不满 的桌会出现在这里。
     */
    public record RoomListEntry(String tableId, int capacity, Ruleset.RuleSet rules,
                                String hostNickname, int seated, List<PublicSeat> seats, long createdAt) {
        public record PublicSeat(int seat, String nickname) {}
    }
}
