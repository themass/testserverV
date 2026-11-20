package com.timeline.game.engine;

import com.timeline.game.domain.GameTypes;
import com.timeline.game.domain.Rules;
import com.timeline.game.protocol.GameErrorCode;

import java.util.List;

/**
 * 引擎产出事件（TS ServerMessage 中引擎相关部分的直译，Java 化命名见 docs/game/protocol.md）。
 * 引擎只产事件、不碰 socket；事件 → wire JSON 的编码在 api/ws 层。
 */
public sealed interface EngineEvent {

    /** 错误回执（wire: error）。 */
    record Error(GameErrorCode code, String message) implements EngineEvent {}

    /** 摆放被接受，可重摆替换（wire: game.planeAccepted）。 */
    record PlaneAccepted(List<Rules.Cell> planes) implements EngineEvent {}

    /**
     * 相位切换（wire: phase.changed）。
     * turn：duel 用；round：melee 用；不用的那侧为 null。
     */
    record PhaseChanged(GameTypes.GamePhase phase, Long deadlineAt, String turn, Integer round) implements EngineEvent {}

    /** duel 一炮结算（wire: game.shot）。nextTurn 是结算后的最终值。 */
    record GameShot(String by, int row, int col, Rules.ShotResult result, String planeId, String nextTurn) implements EngineEvent {}

    /** duel 一架被击落（wire: game.destroyed）。 */
    record PlaneDestroyed(String ownerId, String planeId) implements EngineEvent {}

    /** 终局（wire: game.over）。 */
    record GameOver(GameTypes.GameResult result) implements EngineEvent {}

    /** 座位在线态变化（wire: player.presence）。 */
    record Presence(String playerId, boolean connected) implements EngineEvent {}

    /** melee：某人本轮已提交（无坐标，公开；wire: submitted）。 */
    record Submitted(String playerId, int round) implements EngineEvent {}

    /** melee：本轮结算，私有视图——shots 只含我打的、incoming 只含打我的（wire: round.result）。 */
    record RoundResult(int round, List<GameTypes.TargetShot> shots, List<GameTypes.IncomingShot> incoming,
                       List<DestroyedCount> destroyed, List<String> eliminated) implements EngineEvent {}

    /** melee：某人出局，当场公开（wire: player.out）。 */
    record PlayerOut(String playerId, int round) implements EngineEvent {}

    record DestroyedCount(String playerId, int planesDestroyed) {}
}
