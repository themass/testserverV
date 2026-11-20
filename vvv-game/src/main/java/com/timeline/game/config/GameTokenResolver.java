package com.timeline.game.config;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.core.StringRedisTemplate;

/**
 * Vpn-Token（HTTP 头同名）→ vpn.user.id。
 *
 * 与 vvv-link 的 CacheServiceImpl 读同一份缓存：键 {@code token_<token>}，值是 UserPo 的 JSON。
 * 本模块不 import UserPo（库模块不反向依赖进程模块），只取 JSON 里的 id/name 两个字段。
 * 解不出（键不存在/JSON 畸形/id 缺失）一律返回 null——调用方按未登录处理，不抛异常。
 */
public final class GameTokenResolver {
    private static final Logger LOGGER = LoggerFactory.getLogger(GameTokenResolver.class);
    private static final String TOKEN_KEY_PREFIX = "token_";

    public record PlatformUser(long userId, String name) {}

    private final StringRedisTemplate redis;
    private final ObjectMapper json = new ObjectMapper();

    public GameTokenResolver(StringRedisTemplate redis) {
        this.redis = redis;
    }

    /** token 是握手/请求头原值（不带 token_ 前缀）。 */
    public PlatformUser resolve(String token) {
        if (token == null || token.isBlank()) return null;
        try {
            String raw = redis.opsForValue().get(TOKEN_KEY_PREFIX + token.trim());
            if (raw == null || raw.isBlank()) return null;
            JsonNode node = json.readTree(raw);
            JsonNode id = node.get("id");
            if (id == null || !id.canConvertToLong()) return null;
            JsonNode name = node.get("name");
            return new PlatformUser(id.longValue(), name == null ? null : name.asText(null));
        } catch (Exception e) {
            LOGGER.warn("game token resolve failed: {}", e.toString());
            return null;
        }
    }
}
