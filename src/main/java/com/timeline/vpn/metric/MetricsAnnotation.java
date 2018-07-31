package com.timeline.vpn.metric;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Created by cubn on 16/6/23 13:45.
 */

@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.TYPE, ElementType.METHOD})
public @interface MetricsAnnotation {

    String key() default "";

    Measure type() default Measure.monitor;

}
