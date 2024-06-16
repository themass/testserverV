package com.timeline.vpn.web.common.resolver;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Target({ElementType.PARAMETER})
@Retention(RetentionPolicy.RUNTIME)
public @interface RequestFormParam {
    public static final String FORM_DATA = "formData";
    /**
     * 
     * @Description: 需要实现InvalidForm 类，才能进行校验
     * @return
     */
    boolean invalide() default false;
    /**
     * 
     * @Description: 是否允许为null
     * @return
     */
    boolean canNull() default true;
    /**
     * 
     * @Description: 参数建
     * @return
     */
    String key() default FORM_DATA;
}

