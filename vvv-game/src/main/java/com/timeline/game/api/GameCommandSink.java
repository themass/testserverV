package com.timeline.game.api;

/**
 * 业务侧对 WS 连接事件的消费口（GameWebSocketHandler → GameHub 的唯一接缝）。
 *
 * 传输层完成握手鉴权与信封解码；这里只收解码后的命令与连接事件——
 * TS 版里 Hub 自己 parse + auth 的职责，Java 版按分层拆到了传输层（见 docs/game/protocol.md）。
 */
public interface GameCommandSink {

    /** 握手已通过（userId 即游戏账号）；name 是平台昵称（座位昵称兜底用）。 */
    void onConnect(String clientId, GameConnection conn, long userId, String name);

    /** 收到一条信封合法的命令；回执/推送经 conn.send 发出。 */
    void onCommand(String clientId, com.timeline.game.protocol.GameEnvelopeCodec.Inbound cmd);

    /** 连接关闭（顶号/断线/超时统一走这里；Hub 侧语义 = hub.disconnect）。 */
    void onDisconnect(String clientId);
}
