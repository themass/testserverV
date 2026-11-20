package com.timeline.game.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.timeline.game.protocol.GameEnvelopeCodec;
import com.timeline.game.protocol.GameErrorCode;
import com.timeline.game.protocol.GameEvt;

import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * WS 传输层（TS main.ts 的 wss 回调 + hub.receive 的解码/限流部分直译）。
 *
 * 分层（docs/game/design.md）：这里只做——帧大小闸、信封解码、令牌桶、收发文本；
 * 一切业务语义在 GameCommandSink（GameHub）。解析失败回 error 但保持连接（keep-alive，
 * TS Review Focus #4），连续超频才断连。
 */
public final class GameWebSocketHandler extends TextWebSocketHandler {

    /** 单帧上限（TS main.ts 的 4KB maxPayload 直译；超限不断连只丢帧回 BAD_SHAPE）。 */
    static final int MAX_FRAME_BYTES = 4096;

    private final ObjectMapper mapper;
    private final GameCommandSink sink;
    private final int ratePerMinute;
    private final Map<String, Conn> sessions = new ConcurrentHashMap<>();

    /** 一个连接：WS 会话 + 发送锁（容器不保证 send 并发安全）+ 令牌桶。 */
    private final class Conn implements GameConnection {
        final WebSocketSession ws;
        final long userId;
        final long openedAtNanos = System.nanoTime();
        GameRateLimiter limiter;

        Conn(WebSocketSession ws, long userId) {
            this.ws = ws;
            this.userId = userId;
            this.limiter = new GameRateLimiter(ratePerMinute);
        }

        @Override
        public synchronized void send(String json) {
            try {
                if (ws.isOpen()) ws.sendMessage(new TextMessage(json));
            } catch (IOException ignored) {
                // 半开连接：真正断开由 onClose / 容器超时兜底，这里静默
            }
        }

        @Override
        public void close() {
            try { ws.close(CloseStatus.NORMAL); } catch (IOException ignored) { }
        }
    }

    public GameWebSocketHandler(ObjectMapper mapper, GameCommandSink sink, int ratePerMinute) {
        this.mapper = mapper;
        this.sink = sink;
        this.ratePerMinute = ratePerMinute;
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession ws) {
        Long userId = (Long) ws.getAttributes().get(GameHandshakeInterceptor.ATTR_USER_ID);
        if (userId == null) { closeQuietly(ws); return; }   // 拦截器放行必带 userId；防御
        String name = (String) ws.getAttributes().getOrDefault(GameHandshakeInterceptor.ATTR_USER_NAME, "");
        Conn conn = new Conn(ws, userId);
        sessions.put(ws.getId(), conn);
        sink.onConnect(ws.getId(), conn, userId, name);
    }

    @Override
    protected void handleTextMessage(WebSocketSession ws, TextMessage message) {
        Conn conn = sessions.get(ws.getId());
        if (conn == null) return;
        byte[] payload = message.getPayload().getBytes(java.nio.charset.StandardCharsets.UTF_8);
        if (payload.length > MAX_FRAME_BYTES) {
            sendError(conn, GameErrorCode.BAD_SHAPE, null);   // 保持连接，TS keep-alive 语义
            return;
        }
        if (!conn.limiter.tryAcquire(System.nanoTime())) {
            boolean ban = conn.limiter.registerRejectionAndCheckBan(System.nanoTime(), 3);
            sendError(conn, GameErrorCode.RATE_LIMITED, null);
            if (ban) conn.close();                             // 连续 3 秒超频 → 断连（design.md）
            return;
        }
        GameEnvelopeCodec.DecodeResult decoded = GameEnvelopeCodec.decode(mapper, message.getPayload());
        if (!decoded.ok()) {
            sendError(conn, decoded.error(), null);
            return;
        }
        sink.onCommand(ws.getId(), decoded.inbound());
    }

    @Override
    public void afterConnectionClosed(WebSocketSession ws, CloseStatus status) {
        if (sessions.remove(ws.getId()) != null) sink.onDisconnect(ws.getId());
    }

    @Override
    public void handleTransportError(WebSocketSession ws, Throwable exception) {
        // 容器报错后连接不可恢复；语义等价断线
        Conn conn = sessions.remove(ws.getId());
        if (conn != null) { conn.close(); sink.onDisconnect(ws.getId()); }
    }

    private void sendError(Conn conn, GameErrorCode code, String message) {
        conn.send(GameEnvelopeCodec.encodeError(mapper, code, message, nextServerSeq(conn), null));
    }

    // 服务端 seq：连接内自增即可（客户端只用 seq 去重推送，回执关联走 ref）。
    private final Map<String, Long> seqs = new ConcurrentHashMap<>();
    private long nextServerSeq(Conn conn) {
        return seqs.merge(conn.ws.getId(), 1L, Long::sum);
    }

    private static void closeQuietly(WebSocketSession ws) {
        try { ws.close(CloseStatus.POLICY_VIOLATION); } catch (IOException ignored) { }
    }

    /** 当前在线连接数（健康检查用）。 */
    public int onlineCount() { return sessions.size(); }

    /** 优雅停机：广播关闭前逐个静默断开（TS shutdown 1s 硬切的 Java 侧对应物）。 */
    public void closeAll() {
        for (Conn c : sessions.values()) c.close();
        sessions.clear();
    }
}
