package com.timeline.vpn.common.annotation;

import java.lang.annotation.*;

/**
 * 字段描述
 *
 * @author shanyu
 */
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.FIELD)
@Documented
public @interface FieldDesc {

    /**
     * 是否锁定
     *
     * @return
     */
    boolean locked() default false;

    /**
     * 是否默认
     *
     * @return
     */
    boolean isDefault() default false;

    /**
     * 数值类型，是否需要除于100
     *
     * @return
     */
    boolean percent() default false;

    /**
     * 精度长度
     *
     * @return
     */
    int percentLenth() default 100;

    /**
     * 日期格式
     *
     * @return
     */
    String dateFormat() default "yyyy/MM/dd";

    /**
     * 展示顺序
     *
     * @return
     */
    int idx() default -1;

    /**
     * 字段描述
     *
     * @return
     */
    String desc();

    /**
     * 字段取值
     *
     * @return
     */
    Class<?> value() default Object.class;

    /**
     * 是否必填
     *
     * @return
     */
    boolean isRequired() default false;
}
