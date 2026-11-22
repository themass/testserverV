package com.timeline.game.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.timeline.game.protocol.GameEnvelopeCodec;
import com.timeline.game.protocol.GameErrorCode;
import com.timeline.game.protocol.GameEvt;

import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.PingMessage;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.ConcurrentWebSocketSessionDecorator;
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

    /**
     * 出站装饰器参数（上线加固 2026-11-22）：WS 的 WebSocketSession 不保证 sendMessage
     * 并发安全，而本连接的 send 会同时被 Hub tick 线程（推送）与容器线程（回执/错误）调用。
     * afterConnectionEstablished 里包一层 ConcurrentWebSocketSessionDecorator——它是本类内
     * 唯一持有 session 的地方（Hub 只拿 GameConnection，即 Conn），所以包装点在 Conn 构造处，
     * 全部出站发送路径（含 tick 侧）拿到的都是包装后的对象。
     * 发送超时 5s、缓冲上限 512KB：客户端读得慢时宁可丢连接，不能拖死 tick 线程。
     */
    static final int SEND_TIME_LIMIT_MS = 5000;
    static final int SEND_BUFFER_LIMIT_BYTES = 512 * 1024;

    private final ObjectMapper mapper;
    private final GameCommandSink sink;
    private final int ratePerMinute;
    private final Map<String, Conn> sessions = new ConcurrentHashMap<>();

    /** 一个连接：WS 会话（已包并发装饰器）+ 发送锁（容器不保证 send 并发安全）+ 令牌桶。 */
    private final class Conn implements GameConnection {
        final WebSocketSession ws;
        final long userId;
        final long openedAtNanos = System.nanoTime();
        GameRateLimiter limiter;

        Conn(WebSocketSession raw, long userId) {
            // 唯一包装点：本类是 session 的唯一持有者（Hub 只拿到本 Conn，即 GameConnection），
            // 在这里包一次，tick 线程与容器线程的全部出站发送就都走并发安全的装饰器。
            this.ws = new ConcurrentWebSocketSessionDecorator(raw, SEND_TIME_LIMIT_MS,
                SEND_BUFFER_LIMIT_BYTES);
            this.userId = userId;
            this.limiter = new GameRateLimiter(ratePerMinute);
        }

        @Override
        public synchronized void send(String json) {
            try {
                if (ws.isOpen()) ws.sendMessage(new TextMessage(json));
            } catch (IOException | RuntimeException ignored) {
                // 半开连接：真正断开由 onClose / 容器超时兜底，这里静默。
                // RuntimeException 也要接：装饰器发送超时/缓冲溢出时会抛（并自行关闭会话），
                // 绝不能让它冒回 tick 循环把整轮推送带走。
            }
        }

        @Override
        public void close() {
            try { ws.close(CloseStatus.NORMAL); } catch (IOException | RuntimeException ignored) { }
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

    /**
     * 心跳轮（GamePingDriver 专用，跑在独立 ping 线程上，不在 tick 线程）：
     * 对全部连接发一个空 PingMessage——浏览器对 ping 帧在协议层自动回 pong，
     * 客户端零改动。逐连接 try/catch：一条坏连接不带走整轮；!isOpen 或发送失败
     * 即 close（半开连接一个周期内回收，不占座位）。断开语义仍由容器回调
     * afterConnectionClosed 收敛——这里绝不直调 sink.onDisconnect（Hub 的单线程
     * 假设只允许 tick/容器线程调用它）。返回本轮成功发出的 ping 数（日志/测试用）。
     */
    public int pingAll() {
        int sent = 0;
        for (Conn c : sessions.values()) {
            try {
                if (!c.ws.isOpen()) { c.close(); continue; }
                c.ws.sendMessage(new PingMessage());
                sent++;
            } catch (Exception e) {
                // 发送炸了（含装饰器超时/溢出抛出的运行时异常）＝这条已不可信，关掉
                c.close();
            }
        }
        return sent;
    }

    /** 优雅停机：广播关闭前逐个静默断开（TS shutdown 1s 硬切的 Java 侧对应物）。 */
    public void closeAll() {
        for (Conn c : sessions.values()) c.close();
        sessions.clear();
    }
}
