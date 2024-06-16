package com.timeline.vpn.web.common.config;

import com.timeline.vpn.web.common.interceptor.MyRequestParamMethodArgumentResolver;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter;

public class CustomRequestMappingHandlerAdapter extends RequestMappingHandlerAdapter {

    public CustomRequestMappingHandlerAdapter() {
        // 可以添加自定义的构造函数逻辑
    }

    @Override
    public void afterPropertiesSet() {
        // 可以重写afterPropertiesSet来添加自定义逻辑
        super.afterPropertiesSet();
        getArgumentResolvers().add(0,new MyRequestParamMethodArgumentResolver(true));

    }

    @Override
    protected boolean supportsInternal(HandlerMethod handlerMethod) {
        return super.supportsInternal(handlerMethod);
    }
}