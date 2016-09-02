package com.timeline.vpn.util;


import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import java.io.IOException;
import java.util.UUID;


public class LoggerFilter implements Filter {

    private static final Logger logger = LoggerFactory.getLogger(LoggerFilter.class);
    public static final String TRACE_KEY = "_TRACE_KEY";
    protected FilterConfig config;

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        this.config = filterConfig;
    }

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {
        String id = "trace_" + UUID.randomUUID().hashCode();
        try {
            MDC.put(TRACE_KEY, id);
            chain.doFilter(req, res);
        } catch (IOException e) {

        } catch (Exception e) {
            logger.warn("O.M.G", e);
        } finally {
            MDC.remove(TRACE_KEY);
            logger.debug("removed context information successfully");
        }
    }

    @Override
    public void destroy() {

    }
}

