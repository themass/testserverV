package com.timeline.student.api;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * A cheap ceiling plus a metadata-only access log for /api/student/*.
 *
 * Privacy: the client address is used as an in-memory rate-limit key and is never written to a log or a
 * table. The log line holds status, method, path and duration only. Device ids and bearer keys are not
 * in the path or the log. Learners are minors; "who" is deliberately not recorded here.
 *
 * Device creation gets its own, much lower ceiling so the endpoint cannot be used to fill the table.
 * Fixed one-minute windows, in-process: no Redis, not distributed, and it does not pretend to be.
 */
public class StudentAccessGuard implements Filter {
    private final int perMinute;
    private final int deviceCreatePerMinute;
    /** Off by default: a client-supplied X-Forwarded-For would otherwise let anyone pick a fresh rate-limit key (review B-06). */
    private final boolean trustForwardedFor;
    private final ConcurrentMap<String, AtomicInteger> counters = new ConcurrentHashMap<>();
    private volatile long lastSweep = System.currentTimeMillis() / 60_000L;

    public StudentAccessGuard(int perMinute, int deviceCreatePerMinute, boolean trustForwardedFor) {
        this.perMinute = Math.max(1, perMinute);
        this.deviceCreatePerMinute = Math.max(1, deviceCreatePerMinute);
        this.trustForwardedFor = trustForwardedFor;
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        long minute = System.currentTimeMillis() / 60_000L;
        sweep(minute);
        HttpServletRequest http = (HttpServletRequest) request;
        String path = http.getRequestURI();
        String who = clientKey(http, trustForwardedFor);
        boolean creating = "POST".equals(http.getMethod()) && path.endsWith("/api/student/v1/devices");
        int seen = counters.computeIfAbsent((creating ? "c|" : "a|") + who + '|' + minute, k -> new AtomicInteger()).incrementAndGet();
        int limit = creating ? deviceCreatePerMinute : perMinute;
        long started = System.nanoTime();
        if (seen > limit) {
            if (response instanceof HttpServletResponse res) {
                res.setStatus(429);
                res.setHeader("Retry-After", "30");
                res.setContentType("application/json;charset=UTF-8");
                res.getWriter().write("{\"errno\":429,\"data\":null,\"error\":\"Too many requests\"}");
            }
            System.out.println("[student] 429 " + http.getMethod() + ' ' + path);
            return;
        }
        try {
            chain.doFilter(request, response);
        } finally {
            long ms = (System.nanoTime() - started) / 1_000_000L;
            int status = response instanceof HttpServletResponse res ? res.getStatus() : 0;
            System.out.println("[student] " + status + ' ' + http.getMethod() + ' ' + path + ' ' + ms + "ms");
        }
    }

    private static String clientKey(HttpServletRequest request, boolean trustForwardedFor) {
        String forwarded = trustForwardedFor ? request.getHeader("X-Forwarded-For") : null;
        if (forwarded != null && !forwarded.isBlank()) {
            int comma = forwarded.indexOf(',');
            return (comma > 0 ? forwarded.substring(0, comma) : forwarded).trim();
        }
        String remote = request.getRemoteAddr();
        return remote == null ? "unknown" : remote;
    }

    private void sweep(long minute) {
        if (minute <= lastSweep) return;
        counters.keySet().removeIf(key -> {
            int bar = key.lastIndexOf('|');
            try { return Long.parseLong(key.substring(bar + 1)) < minute - 1L; }
            catch (RuntimeException ex) { return true; }
        });
        lastSweep = minute;
    }
}
