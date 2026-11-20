package com.timeline.game.protocol;

import java.util.Map;

/**
 * 客户端命令（协议层）。词表与 docs/game/protocol.md 的 19 条命令一一对应。
 * wire 上是字符串（"room.create"），这里收口成枚举，未知字符串 → null → UNKNOWN_CMD。
 */
public enum GameCmd {
    PROFILE_GET("profile.get"),
    NICKNAME_SET("nickname.set"),
    ROOM_CREATE("room.create"),
    ROOM_JOIN("room.join"),
    ROOM_LIST("room.list"),
    ROOM_RULES("room.rules"),
    ROOM_READY("room.ready"),
    ROOM_LEAVE("room.leave"),
    ROOM_KICK("room.kick"),
    ROOM_LISTED("room.listed"),
    QUEUE_JOIN("queue.join"),
    QUEUE_LEAVE("queue.leave"),
    PRACTICE_CREATE("practice.create"),
    GAME_PLACE("game.place"),
    GAME_FIRE("game.fire"),
    GAME_ITEM("game.item"),
    RANK_LIST("rank.list"),
    COINS_LEDGER("coins.ledger"),
    COIN_AD_REWARD("coin.adReward");

    public final String wire;

    GameCmd(String wire) { this.wire = wire; }

    private static final Map<String, GameCmd> BY_WIRE;
    static {
        Map<String, GameCmd> m = new java.util.HashMap<>();
        for (GameCmd c : values()) m.put(c.wire, c);
        BY_WIRE = Map.copyOf(m);
    }

    /** 未知命令名返回 null（调用方回 UNKNOWN_CMD），不抛异常——客户端可能先发新版本的命令。 */
    public static GameCmd fromWire(String wire) {
        return wire == null ? null : BY_WIRE.get(wire);
    }
}
