package com.timeline.vpn.common.extension;

import org.springframework.stereotype.Component;

import java.lang.annotation.*;

/**
 * @Description 标注扩展点实现
 * @Author xudongchang
 * @Date 2023/9/23
 */
@Target({ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Component
public @interface Extension {
    public static String DEFAULT = "default";

    /**
     * 扩展点名称
     */
    String name() default DEFAULT;

    /**
     * 描述
     */
    String desc() default "";
}
