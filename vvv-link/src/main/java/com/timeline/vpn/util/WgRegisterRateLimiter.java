package com.timeline.vpn.util;

import java.util.ArrayDeque;
import java.util.Deque;
import java.util.HashMap;
import java.util.Map;

/**
 * WireGuard 设备注册的限流：按用户名做滑动窗口，窗口内超过次数就拒绝。
 * <p>
 * 注册会占用一个隧道地址并同步到所有 WireGuard 服务器，不限速的话单个账号可以耗尽地址池。
 * 状态只在本进程内存里：多实例部署时每个实例各算各的，上限会按实例数放大；
 * 需要严格限制时再把计数挪到 Redis。
 */
public final class WgRegisterRateLimiter {

    /** 每个用户在一个窗口内最多注册的次数。正常使用只会注册一次，换机或重装偶尔两三次。 */
    public static final int DEFAULT_MAX_PER_WINDOW = 5;
    /** 窗口长度：1 小时。 */
    public static final long DEFAULT_WINDOW_MILLIS = 60L * 60 * 1000;

    /** 跟踪的用户数超过这个值时清理一次已经过期的记录，防止内存随用户数无限增长。 */
    private static final int SWEEP_THRESHOLD = 10000;

    private final int maxPerWindow;
    private final long windowMillis;
    private final Map<String, Deque<Long>> hits = new HashMap<>();

    public WgRegisterRateLimiter(int maxPerWindow, long windowMillis) {
        if (maxPerWindow <= 0 || windowMillis <= 0) {
            throw new IllegalArgumentException("maxPerWindow 和 windowMillis 必须大于 0");
        }
        this.maxPerWindow = maxPerWindow;
        this.windowMillis = windowMillis;
    }

    /**
     * 记录一次注册尝试。
     *
     * @return true 表示允许（已计入窗口）；false 表示超限（不计入）
     */
    public synchronized boolean tryAcquire(String key, long nowMillis) {
        Deque<Long> q = hits.computeIfAbsent(key, k -> new ArrayDeque<>());
        while (!q.isEmpty() && nowMillis - q.peekFirst() >= windowMillis) {
            q.pollFirst();
        }
        if (q.size() >= maxPerWindow) {
            return false;
        }
        q.addLast(nowMillis);
        if (hits.size() > SWEEP_THRESHOLD) {
            sweep(nowMillis);
        }
        return true;
    }

    private void sweep(long nowMillis) {
        hits.entrySet().removeIf(e -> e.getValue().isEmpty()
                || nowMillis - e.getValue().peekLast() >= windowMillis);
    }
}
