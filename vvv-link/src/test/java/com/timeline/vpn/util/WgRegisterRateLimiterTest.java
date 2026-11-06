package com.timeline.vpn.util;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;

class WgRegisterRateLimiterTest {

    private static final long WINDOW = 1000L;

    @Test
    void allowsUpToTheLimitThenRejects() {
        WgRegisterRateLimiter limiter = new WgRegisterRateLimiter(3, WINDOW);
        Assertions.assertTrue(limiter.tryAcquire("alice", 0));
        Assertions.assertTrue(limiter.tryAcquire("alice", 1));
        Assertions.assertTrue(limiter.tryAcquire("alice", 2));
        Assertions.assertFalse(limiter.tryAcquire("alice", 3));
    }

    @Test
    void rejectedAttemptsDoNotExtendTheBlock() {
        WgRegisterRateLimiter limiter = new WgRegisterRateLimiter(2, WINDOW);
        Assertions.assertTrue(limiter.tryAcquire("alice", 0));
        Assertions.assertTrue(limiter.tryAcquire("alice", 100));
        Assertions.assertFalse(limiter.tryAcquire("alice", 200));
        Assertions.assertFalse(limiter.tryAcquire("alice", 900));
        // 第一次命中在 0，窗口过去后只释放一个名额，不是整体重置。
        Assertions.assertTrue(limiter.tryAcquire("alice", 1000));
        Assertions.assertFalse(limiter.tryAcquire("alice", 1000));
    }

    @Test
    void usersAreCountedSeparately() {
        WgRegisterRateLimiter limiter = new WgRegisterRateLimiter(1, WINDOW);
        Assertions.assertTrue(limiter.tryAcquire("alice", 0));
        Assertions.assertFalse(limiter.tryAcquire("alice", 1));
        Assertions.assertTrue(limiter.tryAcquire("bob", 1));
    }

    @Test
    void rejectsInvalidConfiguration() {
        Assertions.assertThrows(IllegalArgumentException.class, () -> new WgRegisterRateLimiter(0, WINDOW));
        Assertions.assertThrows(IllegalArgumentException.class, () -> new WgRegisterRateLimiter(1, 0));
    }
}
