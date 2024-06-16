package com.timeline.vpn.web.common.config;

import com.timeline.vpn.web.common.CommonHandlerExceptionResolver;
import com.timeline.vpn.web.common.interceptor.BlackdevHandlerInterceptor;
import com.timeline.vpn.web.common.interceptor.CostHandlerInterceptor;
import com.timeline.vpn.web.common.interceptor.UserCheckHandlerInterceptor;
import com.timeline.vpn.web.common.interceptor.VersionHandlerInterceptor;
import com.timeline.vpn.web.common.resolver.RequestFormParamArgumentResolver;
import com.timeline.vpn.web.common.resolver.StringToDateConverter;
import com.timeline.vpn.web.common.resolver.UserInfoArgumentResolver;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.format.FormatterRegistry;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.servlet.HandlerExceptionResolver;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.web.servlet.i18n.LocaleChangeInterceptor;

import java.util.List;

@Configuration
public class WebConfig implements WebMvcConfigurer {
    @Autowired
    private UserCheckHandlerInterceptor userCheckHandlerInterceptor;
    @Autowired
    private CostHandlerInterceptor costHandlerInterceptor;
    @Autowired
    private BlackdevHandlerInterceptor blackdevHandlerInterceptor;
    @Autowired
    private VersionHandlerInterceptor versionHandlerInterceptor;

    @Autowired
    private UserInfoArgumentResolver userInfoArgumentResolver;
    @Autowired
    private RequestFormParamArgumentResolver requestFormParamArgumentResolver;

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        // LocaleChangeInterceptor
        registry.addInterceptor(new LocaleChangeInterceptor())
                .addPathPatterns("/**/*.json");

        // UserCheckHandlerInterceptor
        registry.addInterceptor(userCheckHandlerInterceptor)
                .addPathPatterns("/**/*.json");

        // CostHandlerInterceptor
        registry.addInterceptor(costHandlerInterceptor)
                .addPathPatterns("/**/*.json");

        // BlackdevHandlerInterceptor
        registry.addInterceptor(blackdevHandlerInterceptor)
                .addPathPatterns("/**/*.json");

        // VersionHandlerInterceptor with exclusions
        registry.addInterceptor(versionHandlerInterceptor)
                .addPathPatterns("/**/*.json")
                .excludePathPatterns(
                        "/version.json",
                        "/login.json",
                        "/logout.json",
                        "/api/monitor/collect.json",
                        "/api/data/**"
                );
    }
    @Override
    public void addArgumentResolvers(List<HandlerMethodArgumentResolver> resolvers) {
        // 添加自定义参数解析器
        resolvers.add(userInfoArgumentResolver);
        resolvers.add(requestFormParamArgumentResolver);
//        resolvers.add(0,new MyRequestParamMethodArgumentResolver(getb));
    }
    @Override
    public void addFormatters(FormatterRegistry registry) {
        registry.addConverter(new StringToDateConverter());
    }
//    @Override
//    public void configureHandlerExceptionResolvers(List<HandlerExceptionResolver> exceptionResolvers) {
//        exceptionResolvers.add(commonHandlerExceptionResolver);
//    }

//
//    @Primary
//    @Order(0)
//    @Bean
//    public CustomRequestMappingHandlerAdapter customRequestMappingHandlerAdapter() {
//        return new CustomRequestMappingHandlerAdapter();
//    }

}