package com.timeline.vpn.common.annotation;

import java.lang.annotation.*;

@Target({ElementType.ANNOTATION_TYPE, ElementType.TYPE, ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
@Inherited
public @interface MethodTimed {
    /**
     * Name of the Timer metric.
     *
     * @return name of the Timer metric
     */
    String value() default "";

    /**
     * List of key-value pair arguments to supply the Timer as extra tags.
     *
     * @return key-value pair of tags
     * @see io.micrometer.core.instrument.Timer.Builder#tags(String...)
     */
    String[] extraTags() default {};

    /**
     * Flag of whether the Timer should be a {@link io.micrometer.core.instrument.LongTaskTimer}.
     *
     * @return whether the timer is a LongTaskTimer
     */
    boolean longTask() default false;

    /**
     * List of percentiles to calculate client-side for the {@link io.micrometer.core.instrument.Timer}.
     * For example, the 95th percentile should be passed as {@code 0.95}.
     *
     * @return percentiles to calculate
     * @see io.micrometer.core.instrument.Timer.Builder#publishPercentiles(double...)
     */
    double[] percentiles() default {0.8,0.9,0.95,0.99};

    /**
     * Whether to enable recording of a percentile histogram for the {@link io.micrometer.core.instrument.Timer Timer}.
     *
     * @return whether percentile histogram is enabled
     * @see io.micrometer.core.instrument.Timer.Builder#publishPercentileHistogram(Boolean)
     */
    boolean histogram() default true;

    /**
     * Description of the {@link io.micrometer.core.instrument.Timer}.
     *
     * @return meter description
     * @see io.micrometer.core.instrument.Timer.Builder#description(String)
     */
    String description() default "";
}
