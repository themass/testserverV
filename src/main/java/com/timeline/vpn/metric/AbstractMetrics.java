package com.timeline.vpn.metric;

import org.apache.commons.lang.StringUtils;

import java.lang.reflect.Method;

/**
 * Created by cubn on 16/6/23 18:03.
 */
public abstract class AbstractMetrics {

    private static final Integer SUCCESS = 1;
    private static final Integer EXCEPTION = 0;

    public Object execute() throws Throwable {
        Method method = getMethod();
        MetricsAnnotation ma = method.getAnnotation(MetricsAnnotation.class);
        Object obj;
        if (ma == null) {
            obj = invoke();
        } else {
            String metricsName = getMetricsName(ma, method);
            long startTime = System.currentTimeMillis();
            Integer status = SUCCESS;
            try {
                obj = invoke();
            } catch (Throwable e) {
                status = EXCEPTION;
                throw e;
            } finally {
                Metrics.time(metricsName, System.currentTimeMillis() - startTime, status);
            }
        }
        return obj; 
    }

    public abstract Method getMethod() throws Exception;

    public abstract Object invoke() throws Throwable;

    private String getMetricsName(MetricsAnnotation ma, Method method) {
        Measure type = ma.type();
        if (type == null) {
            type = Measure.monitor;
        }
        String key = ma.key();
        if (StringUtils.isBlank(key)) {
            key = method.getDeclaringClass().getSimpleName() + MetricContext.WELL + method.getName();
        }
        return type + MetricContext.WELL + key;
    }


}
