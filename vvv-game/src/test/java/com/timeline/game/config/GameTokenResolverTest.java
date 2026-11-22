package com.timeline.game.config;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.lang.reflect.Proxy;
import java.time.Duration;
import java.util.HashMap;
import java.util.Map;

import org.junit.jupiter.api.Test;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

/**
 * token 滑动续期（上线加固 2026-11-22）：resolve 成功后 EXPIRE 回满 1440 分钟、不改值；
 * 键不存在不续期；带 token_ 前缀的完整键（平台 login 返回值形态）同样能解。
 * 打桩方式：子类覆写 StringRedisTemplate 的 opsForValue/expire（都不 final），
 * ValueOperations 接口走动态代理——vvv-game 没有 Mockito，纯 JUnit 够用。
 */
class GameTokenResolverTest {

    /** 假 Redis：store 回放 token 键值，expires 记录 EXPIRE 调用（键 → TTL）。 */
    static final class FakeRedis extends StringRedisTemplate {
        final Map<String, String> store = new HashMap<>();
        final Map<String, Duration> expires = new HashMap<>();

        @SuppressWarnings("unchecked")
        @Override
        public ValueOperations<String, String> opsForValue() {
            return (ValueOperations<String, String>) Proxy.newProxyInstance(
                getClass().getClassLoader(), new Class<?>[] {ValueOperations.class},
                (proxy, method, args) -> {
                    if ("get".equals(method.getName())) return store.get((String) args[0]);
                    throw new UnsupportedOperationException(method.getName());
                });
        }

        @Override
        public Boolean expire(String key, Duration timeout) {
            expires.put(key, timeout);
            return true;
        }
    }

    @Test
    void resolveSuccessSlidesTokenTtl() {
        FakeRedis redis = new FakeRedis();
        redis.store.put("token_abc", "{\"id\":7,\"name\":\"tom\"}");
        GameTokenResolver resolver = new GameTokenResolver(redis);

        GameTokenResolver.PlatformUser user = resolver.resolve("abc");
        assertNotNull(user);
        assertEquals(7, user.userId());
        assertEquals("tom", user.name());
        // 续期口径：1440 分钟（CacheServiceImpl.USERCACH_TIMEOUT 同值），只 EXPIRE（值没被动过）
        assertEquals(Duration.ofMinutes(1440), redis.expires.get("token_abc"));
        assertEquals("{\"id\":7,\"name\":\"tom\"}", redis.store.get("token_abc"));
    }

    /** 平台 login 口径的完整键值（本身带 token_ 前缀）：直接当键解，续的也是同一个键。 */
    @Test
    void resolveAcceptsPrefixedKeyAndSlidesIt() {
        FakeRedis redis = new FakeRedis();
        redis.store.put("token_XYZ", "{\"id\":9,\"name\":\"ann\"}");
        GameTokenResolver resolver = new GameTokenResolver(redis);

        GameTokenResolver.PlatformUser user = resolver.resolve("token_XYZ");
        assertNotNull(user);
        assertEquals(9, user.userId());
        assertEquals(Duration.ofMinutes(1440), redis.expires.get("token_XYZ"));
    }

    @Test
    void missAndGarbageNeverSlide() {
        FakeRedis redis = new FakeRedis();
        redis.store.put("token_bad", "{not json");
        GameTokenResolver resolver = new GameTokenResolver(redis);

        assertNull(resolver.resolve("missing"));
        assertNull(resolver.resolve("bad"));
        assertNull(resolver.resolve(null));
        assertTrue(redis.expires.isEmpty());
    }
}
