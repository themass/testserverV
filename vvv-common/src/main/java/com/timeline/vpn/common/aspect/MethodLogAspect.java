package com.timeline.vpn.common.aspect;

import cn.hutool.core.util.StrUtil;
import com.timeline.vpn.common.annotation.MethodLog;
import com.timeline.vpn.common.utils.JacksonJsonUtil;
import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.AfterReturning;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
import org.aspectj.lang.annotation.Pointcut;
import org.aspectj.lang.reflect.MethodSignature;
import org.springframework.stereotype.Component;

import java.lang.reflect.Method;

/**
 * 方法级别统一日志，切面处理类
 */
@Slf4j
@Aspect
@Component
public class MethodLogAspect {

    public final String CUT_TYPE_BEFORE = "Before";
    public final String CUT_TYPE_AFTER_RETURNING = "AfterReturning";

    @Pointcut("@annotation(com.timeline.vpn.common.annotation.MethodLog)")
    public void logPointCut() {

    }

    @Before("logPointCut()")
    public void aspectBefore(JoinPoint point) throws Throwable {
        pointMethodLog(point, null, CUT_TYPE_BEFORE);
    }


    @AfterReturning(pointcut = "logPointCut()", returning = "result")
    public void aspectAfterReturning(JoinPoint joinPoint, Object result) {
        pointMethodLog(joinPoint, result, CUT_TYPE_AFTER_RETURNING);
    }


    private void pointMethodLog(JoinPoint joinPoint, Object result, String type) {
        try {


            MethodSignature signature = (MethodSignature) joinPoint.getSignature();
            Method method = signature.getMethod();
            MethodLog methodLog = method.getAnnotation(MethodLog.class);

            String code = "";
            if (StrUtil.isBlank(methodLog.code())) {
                code = signature.getDeclaringTypeName() + "." + method.getName();
            } else {
                code = methodLog.code();
            }

            if (type.equals(CUT_TYPE_BEFORE)) {
                Object[] args = joinPoint.getArgs();
                log.info("方法（{}）{},入参：{}", code, methodLog.value(), JacksonJsonUtil.toJsonStr(args));
            }
            if (result != null && type.equals(CUT_TYPE_AFTER_RETURNING) && methodLog.isPointResult()) {
                log.info("方法（{}）{},返参：{}", code, methodLog.value(), JacksonJsonUtil.toJsonStr(result));
            }
        } catch (Exception e) {
            log.error("通用方法日志打印拦截器异常", e);
        }
    }


}
