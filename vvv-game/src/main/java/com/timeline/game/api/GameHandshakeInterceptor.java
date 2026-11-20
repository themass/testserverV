package com.timeline.game.api;

import com.timeline.game.config.GameTokenResolver;

import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.http.server.ServletServerHttpRequest;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.server.HandshakeInterceptor;

import java.util.Map;

/**
 * WS 握手鉴权（TS auth 命令的替代品，见 docs/game/ts-server-spec.md §7 有意差异）：
 * 复用平台链路 {@code Vpn-Token → Redis token_%s → vpn.user.id}（与 HTTP 接口同一校验）。
 * 失败直接拒绝握手（401），不建 WS——比 TS 版"先连后鉴权"少了匿名窗口。
 *
 * 解析出的 userId/name 放进握手属性，GameWebSocketHandler 建连时取出交给 Hub。
 */
public final class GameHandshakeInterceptor implements HandshakeInterceptor {

    public static final String ATTR_USER_ID = "game.userId";
    public static final String ATTR_USER_NAME = "game.userName";
    public static final String HEADER = "Vpn-Token";

    private final GameTokenResolver tokenResolver;

    public GameHandshakeInterceptor(GameTokenResolver tokenResolver) {
        this.tokenResolver = tokenResolver;
    }

    @Override
    public boolean beforeHandshake(ServerHttpRequest request, ServerHttpResponse response,
                                   WebSocketHandler wsHandler, Map<String, Object> attributes) {
        String token = request.getHeaders().getFirst(HEADER);
        // 自定义容器里拿 header 之外，客户端也可能按浏览器 WebSocket 习惯只能带 query——留 query 兜底
        if ((token == null || token.isBlank()) && request instanceof ServletServerHttpRequest servletRequest) {
            token = servletRequest.getServletRequest().getParameter("vpnToken");
        }
        GameTokenResolver.PlatformUser user = tokenResolver.resolve(token);
        if (user == null) {
            response.setStatusCode(org.springframework.http.HttpStatus.UNAUTHORIZED);
            return false;
        }
        attributes.put(ATTR_USER_ID, user.userId());
        attributes.put(ATTR_USER_NAME, user.name() == null ? "" : user.name());
        return true;
    }

    @Override
    public void afterHandshake(ServerHttpRequest request, ServerHttpResponse response,
                               WebSocketHandler wsHandler, Exception exception) {
        // 无需收尾；建连失败时 Hub 只会看到一次 onClose
    }
}
