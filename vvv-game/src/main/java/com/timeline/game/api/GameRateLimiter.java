package com.timeline.game.api;

/**
 * 每连接命令令牌桶（docs/game/design.md 可靠性场景："客户端连发非法包"一行）。
 *
 * 语义：容量 rate/60（约 20），每秒按 rate/60 回补；取不到令牌回 RATE_LIMITED，
 * 连续超限（连续 rateViolations 秒都有拒绝）→ 调用方断连。
 * 时间从参数进（纳秒），可确定性测试。
 */
public final class GameRateLimiter {

    private final double ratePerSecond;
    private final double capacity;
    private double tokens;
    private long lastNanos;
    private int violationSeconds;

    /** @param ratePerMinute 每分钟命令数（game.commandRatePerMinute，默认 1200 ≈ 20/s） */
    public GameRateLimiter(int ratePerMinute) {
        this.ratePerSecond = ratePerMinute / 60.0;
        this.capacity = Math.max(1, ratePerMinute / 60.0);
        this.tokens = capacity;
        this.lastNanos = -1;
    }

    /** 取一枚令牌；返回 false 表示应回 RATE_LIMITED。 */
    public boolean tryAcquire(long nowNanos) {
        if (lastNanos < 0) lastNanos = nowNanos;
        double elapsedSeconds = Math.max(0, (nowNanos - lastNanos) / 1_000_000_000.0);
        lastNanos = nowNanos;
        tokens = Math.min(capacity, tokens + elapsedSeconds * ratePerSecond);
        if (tokens >= 1) {
            tokens -= 1;
            return true;
        }
        return false;
    }

    /**
     * 拒绝一次并返回是否应断连（连续 secondsInRow 个"有拒绝的秒"即断）。
     * 只在被拒时调用；秒差 >1 说明中间有放行（register 不会被调到），连击清零。
     * 同一秒内多次拒绝只计一秒。
     */
    public boolean registerRejectionAndCheckBan(long nowNanos, int secondsInRow) {
        long second = nowNanos / 1_000_000_000L;
        if (second == lastBanSecond) {
            // 同一秒：已计过
        } else if (second == lastBanSecond + 1) {
            violationSeconds++;
        } else {
            violationSeconds = 1;   // 断档（或首次）：从 1 重新计
        }
        lastBanSecond = second;
        return violationSeconds >= secondsInRow;
    }

    private long lastBanSecond = -1;
}
