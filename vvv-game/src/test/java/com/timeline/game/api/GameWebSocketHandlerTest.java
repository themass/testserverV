package com.timeline.game.api;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.fasterxml.jackson.databind.ObjectMapper;

import java.lang.reflect.Field;
import java.net.URI;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicReference;

import org.junit.jupiter.api.Test;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.PingMessage;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketExtension;
import org.springframework.web.socket.WebSocketMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.ConcurrentWebSocketSessionDecorator;

/**
 * 传输层上线加固的对拍（2026-11-22）：
 * ①建连即包 ConcurrentWebSocketSessionDecorator——tick 线程与容器线程并发 send 不再踩
 *   非线程安全的 session；Hub 侧拿到的 GameConnection 就是包装后的通道；
 * ②pingAll 对每个 open 连接发 PingMessage，!isOpen/发送炸 → close，一条坏连接不带走整轮。
 */
class GameWebSocketHandlerTest {

    // ---------------------------------------------------------------- 假件

    /** 假容器会话：记录收到的每一帧（synchronized——并发发送用例真会多线程打进来）。 */
    static final class FakeSession implements WebSocketSession {
        final String id;
        final Map<String, Object> attributes = new HashMap<>();
        final List<WebSocketMessage<?>> sent = Collections.synchronizedList(new ArrayList<>());
        volatile boolean open = true;
        volatile boolean closeCalled = false;
        /** true 时 sendMessage 抛异常（模拟半开/IO 炸）。 */
        volatile boolean failSend = false;

        FakeSession(String id) { this.id = id; }

        @Override public String getId() { return id; }
        @Override public URI getUri() { return URI.create("wss://x/api/game/ws"); }
        @Override public org.springframework.http.HttpHeaders getHandshakeHeaders() {
            return new org.springframework.http.HttpHeaders();
        }
        @Override public Map<String, Object> getAttributes() { return attributes; }
        @Override public java.security.Principal getPrincipal() { return null; }
        @Override public java.net.InetSocketAddress getLocalAddress() { return null; }
        @Override public java.net.InetSocketAddress getRemoteAddress() { return null; }
        @Override public String getAcceptedProtocol() { return null; }
        @Override public void setTextMessageSizeLimit(int size) { }
        @Override public int getTextMessageSizeLimit() { return 8192; }
        @Override public void setBinaryMessageSizeLimit(int size) { }
        @Override public int getBinaryMessageSizeLimit() { return 8192; }
        @Override public List<WebSocketExtension> getExtensions() { return List.of(); }
        @Override public void sendMessage(WebSocketMessage<?> message) throws java.io.IOException {
            if (failSend) throw new java.io.IOException("boom");
            sent.add(message);
        }
        @Override public boolean isOpen() { return open; }
        @Override public void close() { closeCalled = true; open = false; }
        @Override public void close(CloseStatus status) { closeCalled = true; open = false; }
    }

    /** 假 Hub：只记连接事件与拿到的通道。 */
    static final class FakeSink implements GameCommandSink {
        final Map<String, GameConnection> conns = new HashMap<>();
        final List<String> connected = Collections.synchronizedList(new ArrayList<>());
        final List<String> disconnected = Collections.synchronizedList(new ArrayList<>());

        @Override public void onConnect(String clientId, GameConnection conn, long userId, String name) {
            conns.put(clientId, conn);
            connected.add(clientId);
        }
        @Override public void onCommand(String clientId,
                                        com.timeline.game.protocol.GameEnvelopeCodec.Inbound cmd) { }
        @Override public void onDisconnect(String clientId) { disconnected.add(clientId); }
    }

    private static FakeSession session(String id, long userId) {
        FakeSession s = new FakeSession(id);
        s.attributes.put(GameHandshakeInterceptor.ATTR_USER_ID, userId);
        s.attributes.put(GameHandshakeInterceptor.ATTR_USER_NAME, "n" + userId);
        return s;
    }

    // ---------------------------------------------------------------- ① 装饰器

    @Test
    void establishedWrapsSessionInConcurrentDecorator() throws Exception {
        GameWebSocketHandler handler = new GameWebSocketHandler(new ObjectMapper(), new FakeSink(), 1200);
        FakeSession raw = session("c1", 42);
        handler.afterConnectionEstablished(raw);

        // Hub 拿到的 GameConnection 发送必须落到原始会话（链路通）……
        GameConnection conn = ((FakeSink) sinkOf(handler)).conns.get("c1");
        conn.send("{\"evt\":\"profile_now\"}");
        assertEquals(1, raw.sent.size());

        // ……且 Conn 持有的是装饰器包装（反射读 Conn.ws；反射只在这里用，测试私有实现细节）
        Object inner = connField(handler, "c1", "ws");
        assertInstanceOf(ConcurrentWebSocketSessionDecorator.class, inner);
        ConcurrentWebSocketSessionDecorator deco = (ConcurrentWebSocketSessionDecorator) inner;
        assertEquals(GameWebSocketHandler.SEND_TIME_LIMIT_MS, deco.getSendTimeLimit());
        assertEquals(GameWebSocketHandler.SEND_BUFFER_LIMIT_BYTES, deco.getBufferSizeLimit());
    }

    /** 多线程同打一条连接：装饰器负责排队，全部帧到达且无异常逃逸（旧代码这里就是竞态点）。 */
    @Test
    void concurrentSendAllArrive() throws Exception {
        FakeSink sink = new FakeSink();
        GameWebSocketHandler handler = new GameWebSocketHandler(new ObjectMapper(), sink, 1200);
        FakeSession raw = session("c1", 42);
        handler.afterConnectionEstablished(raw);
        GameConnection conn = sink.conns.get("c1");

        int threads = 4, each = 50;
        CountDownLatch start = new CountDownLatch(1);
        AtomicReference<Throwable> err = new AtomicReference<>();
        List<Thread> ts = new ArrayList<>();
        for (int t = 0; t < threads; t++) {
            Thread th = new Thread(() -> {
                try {
                    start.await();
                    for (int i = 0; i < each; i++) conn.send("{\"i\":" + i + "}");
                } catch (Throwable e) { err.set(e); }
            });
            ts.add(th); th.start();
        }
        start.countDown();
        for (Thread th : ts) th.join(10_000);
        assertEquals(null, err.get());
        assertEquals(threads * each, raw.sent.size());
    }

    /** 装饰器溢出/超时会抛运行时异常：Conn.send 必须咽下，不能冒回 tick 循环。 */
    @Test
    void sendSwallowsDecoratorRuntimeException() {
        FakeSink sink = new FakeSink();
        GameWebSocketHandler handler = new GameWebSocketHandler(new ObjectMapper(), sink, 1200);
        FakeSession raw = session("c1", 42);
        handler.afterConnectionEstablished(raw);
        raw.failSend = true;   // 装饰器把 IOException 照抛；这里再验证运行时异常路径不炸
        GameConnection conn = sink.conns.get("c1");
        conn.send("{}");       // 不抛即通过
        // 半开（!isOpen）发送直接跳过
        raw.open = false;
        conn.send("{}");
    }

    // ---------------------------------------------------------------- ② 心跳

    @Test
    void pingAllSendsPingToEveryOpenConnAndClosesBadOnes() {
        FakeSink sink = new FakeSink();
        GameWebSocketHandler handler = new GameWebSocketHandler(new ObjectMapper(), sink, 1200);
        FakeSession good = session("c1", 1);
        FakeSession dead = session("c2", 2);
        handler.afterConnectionEstablished(good);
        handler.afterConnectionEstablished(dead);

        dead.open = false;                      // 半开：isOpen 已 false
        int sent = handler.pingAll();
        assertEquals(1, sent);
        assertInstanceOf(PingMessage.class, good.sent.get(0));
        assertTrue(dead.closeCalled);           // 关掉

        // 发送炸（IOException）→ 该连接被 close，另一条不受影响
        FakeSession bad = session("c3", 3);
        handler.afterConnectionEstablished(bad);
        bad.failSend = true;
        sent = handler.pingAll();
        assertEquals(1, sent);
        assertTrue(bad.closeCalled);
        assertEquals(2, good.sent.size());
    }

    // ---------------------------------------------------------------- 反射小工具

    private static FakeSink sinkOf(GameWebSocketHandler handler) throws Exception {
        Field f = GameWebSocketHandler.class.getDeclaredField("sink");
        f.setAccessible(true);
        return (FakeSink) f.get(handler);
    }

    private static Object connField(GameWebSocketHandler handler, String clientId, String field)
        throws Exception {
        Field mapF = GameWebSocketHandler.class.getDeclaredField("sessions");
        mapF.setAccessible(true);
        Object conn = ((Map<?, ?>) mapF.get(handler)).get(clientId);
        Field wsF = conn.getClass().getDeclaredField(field);
        wsF.setAccessible(true);
        return wsF.get(conn);
    }
}
