package com.timeline.vpn.common.service.impl;

/**
 * @Author： liguoqing
 * @Date： 2024/4/30 15:43
 * @Describe：
 */
public interface RedisLockService {
    boolean acquireLock(String lockKey, String clientId, long expireTimeInMillis);

    void releaseLock(String lockKey, String clientId);
}
