package com.timeline.vpn.common.annotation;

import java.lang.annotation.*;

/**
 * 幂等注解
 *
 * @Author xudongchang
 * @Date 2023/12/13
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface Idempotent {
    /**
     * 幂等key前缀，作为redis缓存key的前缀
     */
    String prefix() default "idempotent:";

    /**
     * 幂等过期时间，即：在此时间段内，进行幂等拦截。
     */
    long expireMillis() default 5 * 60 * 1000;

}
