package com.timeline.poetry.api;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Published content is readable without a token by decision, so it still needs two things:
 * a per-client request log and a cheap ceiling that keeps one client from emptying the box.
 * This is a fixed one-minute window counter, deliberately in-process: no Redis, no new
 * dependency. It is not a distributed limit and it does not pretend to be one.
 */
public class PoetryAccessGuard implements Filter {
    private final int perMinuteLimit;
    private final ConcurrentMap<String, AtomicInteger> counters = new java.util.concurrent.ConcurrentHashMap<>();
    private volatile long lastSweep = System.currentTimeMillis() / 60_000L;

    public PoetryAccessGuard(int perMinuteLimit) { this.perMinuteLimit = Math.max(1, perMinuteLimit); }

    @Override public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        long minute = System.currentTimeMillis() / 60_000L;
        sweep(minute);
        HttpServletRequest http = (HttpServletRequest) request;
        String path = http.getRequestURI();
        String client = clientKey(http);
        int seen = counters.computeIfAbsent(client + '/' + minute, k -> new AtomicInteger()).incrementAndGet();
        long started = System.nanoTime();
        if (seen > perMinuteLimit) {
            if (response instanceof HttpServletResponse res) {
                res.setStatus(429);
                res.setContentType("application/json;charset=UTF-8");
                res.getWriter().write("{\"errno\":429,\"data\":null,\"error\":\"Too many requests\"}");
            }
            System.out.println("[poetry] 429 " + http.getMethod() + ' ' + path + " client=" + client
                + " rpm=" + seen);
            return;
        }
        try {
            chain.doFilter(request, response);
        } finally {
            long ms = (System.nanoTime() - started) / 1_000_000L;
            int status = response instanceof HttpServletResponse res ? res.getStatus() : 0;
            System.out.println("[poetry] " + status + ' ' + http.getMethod() + ' ' + path
                + " client=" + client + " " + ms + "ms");
        }
    }

    private static String clientKey(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
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
            int slash = key.lastIndexOf('/');
            try { return Long.parseLong(key.substring(slash + 1)) < minute - 1L; }
            catch (RuntimeException ex) { return true; }
        });
        lastSweep = minute;
    }
}
