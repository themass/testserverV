package com.timeline.game.api;

/**
 * 传输层暴露给业务（Hub）的发送通道（TS hub.ts Session.send/close 直译）。
 * 实现是 WebSocket 会话；Hub 侧只认这个接口，方便测试注入假连接。
 */
public interface GameConnection {

    /** 发送一条已编码的 wire JSON。实现须容忍会话已关闭（静默丢弃）。 */
    void send(String json);

    /** 主动断开（顶号、连续超频时使用；幂等）。 */
    void close();
}
