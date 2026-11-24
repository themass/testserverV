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
        // health.json 必须排除：它是部署自检（裸 curl，没有客户端签名 UA）。
        // HostFilter 对无签名 UA 得到 DevApp=null（DeviceUtil.getAPPInfo 匹配不到
        // VVV/x.y.z.w 正则返回 null），UserCheckHandlerInterceptor 见 null 直接
        // throw RuntimeException("welcome") → 全局兜底 errno 10000，自检永远红。
        registry.addInterceptor(userCheckHandlerInterceptor)
                .addPathPatterns("/**/*.json")
                .excludePathPatterns(HEALTH_EXCLUSIONS);

        // CostHandlerInterceptor
        registry.addInterceptor(costHandlerInterceptor)
                .addPathPatterns("/**/*.json");

        // BlackdevHandlerInterceptor
        registry.addInterceptor(blackdevHandlerInterceptor)
                .addPathPatterns("/**/*.json")
                .excludePathPatterns(HEALTH_EXCLUSIONS);

        // VersionHandlerInterceptor with exclusions
        registry.addInterceptor(versionHandlerInterceptor)
                .addPathPatterns("/**/*.json")
                .excludePathPatterns(
                        "/version.json",
                        "/login.json",
                        "/logout.json",
                        "/api/monitor/collect.json",
                        "/api/data/**",
                        // 同上：签名/黑名单/版本都要读 DevApp，裸 curl 的部署自检进不去
                        "/api/photosolve/v1/health.json");
    }

    /** 部署自检端点：不带客户端签名，必须绕开所有读 DevAppContext 的拦截器。 */
    private static final String[] HEALTH_EXCLUSIONS = {"/api/photosolve/v1/health.json"};
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