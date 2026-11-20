package com.timeline.game.protocol;

import java.util.Map;

/**
 * 服务端事件（协议层）。词表与 docs/game/protocol.md 的事件清单对应。
 * "error" 也是事件：统一错误回执。
 */
public enum GameEvt {
    TABLE_STATE("table.state"),
    TABLE_KICKED("table.kicked"),
    TABLE_CLOSED("table.closed"),
    QUEUE_STATUS("queue.status"),
    QUEUE_TIMEOUT("queue.timeout"),
    ROOM_LIST("room.list"),
    PHASE_CHANGED("phase.changed"),
    GAME_PLANE_ACCEPTED("game.planeAccepted"),
    GAME_SHOT("game.shot"),
    GAME_DESTROYED("game.destroyed"),
    GAME_OVER("game.over"),
    GAME_SUBMITTED("game.submitted"),
    GAME_ROUND_RESULT("game.roundResult"),
    GAME_PLAYER_OUT("game.playerOut"),
    PLAYER_PRESENCE("player.presence"),
    PROFILE_NOW("profile.now"),
    RANK_CHANGED("rank.changed"),
    RANK_LIST("rank.list"),
    COINS_NOW("coins.now"),
    COINS_LEDGER("coins.ledger"),
    ERROR("error");

    public final String wire;

    GameEvt(String wire) { this.wire = wire; }

    private static final Map<String, GameEvt> BY_WIRE;
    static {
        Map<String, GameEvt> m = new java.util.HashMap<>();
        for (GameEvt e : values()) m.put(e.wire, e);
        BY_WIRE = Map.copyOf(m);
    }

    public static GameEvt fromWire(String wire) {
        return wire == null ? null : BY_WIRE.get(wire);
    }
}
