package com.timeline.vpn.web.common.interceptor;

import org.springframework.beans.factory.config.ConfigurableBeanFactory;
import org.springframework.core.MethodParameter;
import org.springframework.web.method.annotation.RequestParamMethodArgumentResolver;

/**
 * @Author： liguoqing
 * @Date： 2024/6/16 13:01
 * @Describe：
 */
public class MyRequestParamMethodArgumentResolver extends RequestParamMethodArgumentResolver {
    public MyRequestParamMethodArgumentResolver(boolean useDefaultResolution) {
        super(useDefaultResolution);
    }

    public MyRequestParamMethodArgumentResolver(ConfigurableBeanFactory beanFactory, boolean useDefaultResolution) {
        super(beanFactory, useDefaultResolution);
    }

    @Override
    protected NamedValueInfo createNamedValueInfo(MethodParameter parameter) {
        return super.createNamedValueInfo(parameter);
    }
}
