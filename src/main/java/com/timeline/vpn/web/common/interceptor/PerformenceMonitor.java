package com.timeline.vpn.web.common.interceptor;

import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Pointcut;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * 
 * @ClassName: PerformenceMonitor
 * @Description: 拦截器，拦截pobuilder和vobuilder时间消耗，并打印日志
 * @author gqli
 * @date 2015年8月12日 下午8:22:15
 *
 */
@Aspect
@Component
public class PerformenceMonitor {

    private static final Logger LOGGER = LoggerFactory.getLogger(PerformenceMonitor.class);


    /**
     * 监控com.lianjia.folio.dao.po包及其子包的所有public方法 <功能详细描述>
     * 
     * @see [类、类#方法、类#成员]
     */
    @Pointcut("execution(* com.timeline.vpn.dao.*.*(..))||"
            + "execution(* com.timeline.vpn.service.impl.*.*(..))")
    private void pointCutMethod() {
        // 用来实现aop
    }

    // 声明环绕通知
    @Around("pointCutMethod()")
    public Object doAround(ProceedingJoinPoint pjp) throws Throwable {
        long begin = System.currentTimeMillis();
        Object o = pjp.proceed();
        long end = System.currentTimeMillis();
        long time = end - begin;
        String methed =
                pjp.getTarget().getClass().getSimpleName() + "." + pjp.getSignature().getName();
        if(time>300)
            LOGGER.error("{}:{}", methed, time);
        return o;
    }
}
