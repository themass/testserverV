package com.timeline.student.api;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Set;

/**
 * Allow-list CORS for /api/student/*. Auth is a Bearer header, never a cookie, so credentials are not
 * allowed cross-origin and the origin is reflected only when it is in the configured list.
 * Defaults cover the browser dev server and the Capacitor shells (see frontend-and-mobile-strategy 4.1).
 */
public class StudentCorsFilter implements Filter {
    public static final Set<String> SHELL_DEFAULTS = Set.of("capacitor://localhost", "http://localhost",
        "https://localhost", "ionic://localhost");
    private final Set<String> allowed;

    public StudentCorsFilter(Set<String> allowed) { this.allowed = Set.copyOf(allowed); }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest http = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;
        String origin = http.getHeader("Origin");
        res.addHeader("Vary", "Origin");
        if (origin != null && matches(origin)) {
            res.setHeader("Access-Control-Allow-Origin", origin);
            res.setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
            res.setHeader("Access-Control-Allow-Headers", "Authorization, Content-Type, X-Student-Internal-Token");
            res.setHeader("Access-Control-Max-Age", "600");
            if ("OPTIONS".equals(http.getMethod())) { res.setStatus(204); return; }
        } else if ("OPTIONS".equals(http.getMethod()) && origin != null) {
            res.setStatus(403);
            return;
        }
        chain.doFilter(request, response);
    }

    /** Exact match, or a "https://*.appid.localhost" style suffix entry for per-app Capacitor hosts. */
    boolean matches(String origin) {
        if (allowed.contains(origin)) return true;
        for (String entry : allowed) {
            int star = entry.indexOf("*.");
            if (star > 0) {
                String scheme = entry.substring(0, star);
                String suffix = entry.substring(star + 1);
                if (origin.startsWith(scheme) && origin.endsWith(suffix) && origin.length() > scheme.length() + suffix.length()) return true;
            }
        }
        return false;
    }
}
