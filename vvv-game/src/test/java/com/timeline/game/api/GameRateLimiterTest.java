package com.timeline.game.api;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** 令牌桶单测：突发容量、回补速率、连拒断连判定（确定性纳秒时间入参）。 */
class GameRateLimiterTest {

    private static final long SEC = 1_000_000_000L;

    @Test
    void 初始容量允许突发二十条() {
        GameRateLimiter r = new GameRateLimiter(1200);   // 20/s
        long t = 0;
        for (int i = 0; i < 20; i++) assertTrue(r.tryAcquire(t), "第" + i + "条应放行");
        assertFalse(r.tryAcquire(t), "第21条应被拒");
    }

    @Test
    void 一秒后回补二十枚令牌() {
        GameRateLimiter r = new GameRateLimiter(1200);
        for (int i = 0; i < 20; i++) r.tryAcquire(0);
        assertFalse(r.tryAcquire(0));
        for (int i = 0; i < 20; i++) assertTrue(r.tryAcquire(SEC), "一秒后第" + i + "条应放行");
        assertFalse(r.tryAcquire(SEC));
    }

    @Test
    void 半秒回补十枚() {
        GameRateLimiter r = new GameRateLimiter(1200);
        for (int i = 0; i < 20; i++) r.tryAcquire(0);
        for (int i = 0; i < 10; i++) assertTrue(r.tryAcquire(SEC / 2), "半秒后第" + i + "条应放行");
        assertFalse(r.tryAcquire(SEC / 2));
    }

    @Test
    void 令牌有上限不无限囤积() {
        GameRateLimiter r = new GameRateLimiter(1200);
        for (int i = 0; i < 10; i++) r.tryAcquire(0);
        // 空转 10 分钟也只攒回一桶（20），而不是 12000
        for (int i = 0; i < 20; i++) assertTrue(r.tryAcquire(600 * SEC));
        assertFalse(r.tryAcquire(600 * SEC));
    }

    @Test
    void 连续三秒被拒才判断连() {
        GameRateLimiter r = new GameRateLimiter(60);    // 1/s，容量 1
        r.tryAcquire(0);
        // 第 0 秒起每 0.1 秒打一发，全部被拒：第 3 个"拒绝秒"触发断连
        assertFalse(r.registerRejectionAndCheckBan(SEC, 3));           // 第1秒
        assertFalse(r.registerRejectionAndCheckBan(SEC + 100_000_000L, 3)); // 仍在第1秒
        assertFalse(r.registerRejectionAndCheckBan(2 * SEC, 3));       // 第2秒
        assertTrue(r.registerRejectionAndCheckBan(3 * SEC, 3), "第3个连续拒绝秒应触发断连");
    }

    @Test
    void 中间放行一秒则连击清零() {
        GameRateLimiter r = new GameRateLimiter(60);
        r.registerRejectionAndCheckBan(SEC, 3);            // 第1个拒绝秒
        r.registerRejectionAndCheckBan(2 * SEC, 3);        // 第2个连续拒绝秒
        // 第 3、4 秒放行（放行时不会调 register），第 5 秒再拒 → 连击从 1 重新开始
        assertEquals(false, r.registerRejectionAndCheckBan(5 * SEC, 3), "断档后第一次拒绝不应断连");
        assertEquals(false, r.registerRejectionAndCheckBan(6 * SEC, 3), "第 2 个拒绝秒");
        assertTrue(r.registerRejectionAndCheckBan(7 * SEC, 3), "重新连续三秒才断连");
    }
}
