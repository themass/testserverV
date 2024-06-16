package com.timeline.vpn.common.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;

/**
 * @Author： liguoqing
 * @Date： 2024/4/30 15:43
 * @Describe：
 */
@Service
public class RedisLockServiceImpl implements RedisLockService {
    @Autowired
    private StringRedisTemplate stringRedisTemplate;

    @Override
    public boolean acquireLock(String lockKey, String clientId, long expireTimeInMillis) {
        return stringRedisTemplate.opsForValue().setIfAbsent(lockKey, clientId, Duration.ofMillis(expireTimeInMillis));
    }

    @Override
    public void releaseLock(String lockKey, String clientId) {
        String currentValue = stringRedisTemplate.opsForValue().get(lockKey);
        if (currentValue != null && currentValue.equals(clientId)) {
            // 删除锁
            stringRedisTemplate.delete(lockKey);
        }
    }
}
