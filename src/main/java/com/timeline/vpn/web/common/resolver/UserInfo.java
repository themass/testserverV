package com.timeline.vpn.web.common.resolver;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * userId parameter注解，用于从cookie中获取用户ID<br/>
 * 相当于 @CustomArgument(resolver = ArgumentResolver.RESOLVER_USER_ID) String userId <br/>
 * 主要用于简化Controller注解
 */
@Target({ElementType.PARAMETER})
@Retention(RetentionPolicy.RUNTIME)
public @interface UserInfo {
    boolean required() default false;

    boolean appinfo() default true;
}
