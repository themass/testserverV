package com.timeline.vpn.common.extension;

import java.lang.annotation.*;

/**
 * @Description 标注扩展接口
 * @Author xudongchang
 * @Date 2023/9/23
 */
@Target({ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface Extensible {
    String DEFAULT = "/default";

    /**
     * 路径，类似url
     */
    String path() default DEFAULT;

    /**
     * 描述
     */
    String desc() default "";
}
