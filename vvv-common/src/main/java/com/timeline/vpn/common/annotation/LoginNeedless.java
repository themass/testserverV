package com.timeline.vpn.common.annotation;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * 免登陆校验的注解标识 使用此注解的controller会被spring mvc的登陆拦截器忽略
 */
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.METHOD, ElementType.TYPE})
public @interface LoginNeedless {

    LoginType loginType() default LoginType.NEED_CURRENT_USER;

    public enum LoginType {
        NONE(), NEED_CURRENT_USER(),
        ;

    }
}
