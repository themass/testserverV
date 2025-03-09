package com.timeline.vpn.common.aspect;

import com.timeline.vpn.common.annotation.MethodTimed;
import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.Signature;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Pointcut;
import org.aspectj.lang.reflect.MethodSignature;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.lang.reflect.Method;
import java.util.Optional;
import java.util.concurrent.CompletionStage;
import java.util.function.Function;

/**
 * 由@Timed改造而来
 */
@Aspect
@Component
@Slf4j
public class MethodTimedAspect {
    public static final String DEFAULT_METRIC_NAME = "method.timed";
    public static final String DEFAULT_EXCEPTION_TAG_VALUE = "none";
    /**
     * Tag key for an exception.
     *
     * @since 1.1.0
     */
    public static final String EXCEPTION_TAG = "exception";


    @Pointcut("@within(com.timeline.vpn.common.annotation.MethodTimed)")
    private void typeMonitor() {
    }

    @Pointcut("@annotation(com.timeline.vpn.common.annotation.MethodTimed)")
    private void methodMonitor() {
    }

    @Around("typeMonitor() || methodMonitor()")
    public Object timedMethod(ProceedingJoinPoint pjp) throws Throwable {
        Method method = ((MethodSignature) pjp.getSignature()).getMethod();
        MethodTimed timed = method.getAnnotation(MethodTimed.class);
        if (timed == null) {
            method = pjp.getTarget().getClass().getMethod(method.getName(), method.getParameterTypes());
            timed = method.getAnnotation(MethodTimed.class);
            timed = (timed == null) ? pjp.getTarget().getClass().getAnnotation(MethodTimed.class) : timed;
        }
        final String metricName = timed.value().isEmpty() ? DEFAULT_METRIC_NAME : timed.value();
        return processWithTimer(pjp, timed, metricName);
    }

    private Object processWithTimer(ProceedingJoinPoint pjp, MethodTimed timed, String metricName) throws Throwable {

        String method = "";
        long times = System.currentTimeMillis();
        try {
            Signature signature = pjp.getSignature();
            method = signature.getDeclaringType().getSimpleName() + "." + signature.getName();
            return pjp.proceed();
        } catch (Exception ex) {
            throw ex;
        } finally {
            long cost = System.currentTimeMillis() - times;
            if (cost > 200) {
                log.info("Method耗时, name={}, cost={}", method, System.currentTimeMillis() - times);
            }
        }
    }

}
