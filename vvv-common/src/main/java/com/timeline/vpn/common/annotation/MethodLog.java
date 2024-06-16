package com.timeline.vpn.common.annotation;

import java.lang.annotation.*;

@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface MethodLog {

    String value() default "";

    String code() default "";

    boolean isPointResult() default true;
}
