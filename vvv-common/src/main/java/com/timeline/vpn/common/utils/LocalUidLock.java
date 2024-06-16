package com.timeline.vpn.common.utils;

import cn.hutool.core.lang.Assert;
import lombok.RequiredArgsConstructor;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

/**
 * 对同一个uid的请求进行加锁
 * 目前考虑的比较简单：
 * 1. 同一个uid的所有交互分为两类，前端调用和callback调用
 * 2. 这两类调用都通过ws和redis pub/sub保证了同一个uid的请求都是在同一台机器上执行，所以单机加锁即可
 * 3. 目前简单处理为所有交互加锁串行
 * todo 后续按需改为分布式加锁，且部分交互可能可以并行
 */
@RequiredArgsConstructor
public class LocalUidLock implements AutoCloseable {

    private final LockInfo lock;

    private static final Lock GLOBAL_LOCK = new ReentrantLock();

    private static final Map<String, LockInfo> LOCK_MAP = new HashMap<>();

    @Override
    public void close() {
        lock.unlock();
    }

    public static LocalUidLock lock(String uid) {
        LockInfo lock;
        GLOBAL_LOCK.lock();
        try {
            lock = LOCK_MAP.computeIfAbsent(uid, LockInfo::new);
            ++lock.lockCnt;
        } finally {
            GLOBAL_LOCK.unlock();
        }
        lock.lock.lock();
        return new LocalUidLock(lock);
    }

    @RequiredArgsConstructor
    private static class LockInfo {
        private final String uid;
        private int lockCnt;
        private final Lock lock = new ReentrantLock();

        public void unlock() {
            lock.unlock();
            GLOBAL_LOCK.lock();
            try {
                if (--lockCnt <= 0) {
                    LockInfo old = LOCK_MAP.remove(uid);
                    Assert.notNull(old, "impossible");
                }
            } finally {
                GLOBAL_LOCK.unlock();
            }
        }
    }
}
