package com.timeline.vpn.metric;

import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Pointcut;
import org.aspectj.lang.reflect.MethodSignature;

import java.lang.reflect.Method;

/**
 * Created by cubn on 16/6/23 13:51.
 */
@Aspect
public class MetricsAspect extends AbstractMetrics {

    private static ThreadLocal<ProceedingJoinPoint> jpLocal = new ThreadLocal<ProceedingJoinPoint>();

    @Pointcut("@annotation(com.timeline.vpn.metric.MetricsAnnotation)")
    public void AspectPoint() {
    }

    @Around("AspectPoint()")
    public Object around(ProceedingJoinPoint jp) throws Throwable {
        jpLocal.set(jp);
        try{
            return execute();
        }finally {
            jpLocal.remove();
        }
    }

    @Override
    public Method getMethod() throws Exception {
        return getMethod(jpLocal.get());
    }

    @Override
    public Object invoke() throws Throwable {
        return jpLocal.get().proceed();
    }

    private Method getMethod(JoinPoint jp) throws Exception {
        MethodSignature msig = (MethodSignature) jp.getSignature();
        Method method = msig.getMethod();
        return method;
    }

}
