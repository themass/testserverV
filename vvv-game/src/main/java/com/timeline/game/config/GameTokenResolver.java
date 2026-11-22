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
    /**
     * 滑动续期 TTL（分钟）：与 vvv-link CacheServiceImpl.USERCACH_TIMEOUT 同口径（60*24=1440）。
     * 每次 resolve 成功就把键的 TTL 重置回满值（只 EXPIRE，不改值）——游戏活跃会话不掉线，
     * 闲置满 24h 自然过期。
     */
    static final long SLIDE_TTL_MINUTES = 60 * 24;

    public record PlatformUser(long userId, String name) {}

    private final StringRedisTemplate redis;
    private final ObjectMapper json = new ObjectMapper();

    public GameTokenResolver(StringRedisTemplate redis) {
        this.redis = redis;
    }

    /**
     * token 是握手/请求头原值。两种形态都认：
     * ① 裸 token（AuthUtil.nameToToken 的输出，标准 Base64，字母表里没有下划线）→ 键 = token_ + token；
     * ② 平台 login.json 口径的完整键值（CacheServiceImpl.putUser 的返回值本身就带 token_ 前缀，
     *    App 端把它原样放进 Vpn-Token）→ 直接当键用。
     * ②是①加前缀的严格超集且不歧义（Base64 无下划线），所以同一个 token 在平台接口与
     * 游戏接口之间可直接互换。
     */
    public PlatformUser resolve(String token) {
        if (token == null || token.isBlank()) return null;
        try {
            String t = token.trim();
            String key = t.startsWith(TOKEN_KEY_PREFIX) ? t : TOKEN_KEY_PREFIX + t;
            String raw = redis.opsForValue().get(key);
            if (raw == null || raw.isBlank()) return null;
            JsonNode node = json.readTree(raw);
            JsonNode id = node.get("id");
            if (id == null || !id.canConvertToLong()) return null;
            JsonNode name = node.get("name");
            slide(key);
            return new PlatformUser(id.longValue(), name == null ? null : name.asText(null));
        } catch (Exception e) {
            LOGGER.warn("game token resolve failed: {}", e.toString());
            return null;
        }
    }

    /**
     * 滑动续期（只 EXPIRE，绝不改值——token 值格式归 vvv-link 管）：
     * 续期失败（Redis 抖动）不影响本次解析结果——续期是增益，鉴权是主路。
     */
    private void slide(String key) {
        try {
            redis.expire(key, java.time.Duration.ofMinutes(SLIDE_TTL_MINUTES));
        } catch (Exception e) {
            LOGGER.warn("game token slide failed: {}", e.toString());
        }
    }

    /** 健康检查用：Redis 是否读得通（PING，不碰任何业务键）。 */
    public boolean redisAlive() {
        // 早期实现是 hasKey("token_health-probe")——那个键永远不会存在，
        // Redis 健康也返回 false（首次真机自检抓出）。PING 与键空间无关，
        // 走 execute 回调让模板负责归还连接。
        // Spring Data Redis 的 ping() 返回状态字符串 "PONG"，走 execute 回调让模板负责归还连接。
        String p = redis.execute((org.springframework.data.redis.core.RedisCallback<String>)
            connection -> connection.ping());
        return p != null && "PONG".equalsIgnoreCase(p);
    }
}
