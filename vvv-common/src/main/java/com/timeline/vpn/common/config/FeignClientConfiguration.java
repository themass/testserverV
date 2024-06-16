package com.timeline.vpn.common.config;

import com.timeline.vpn.common.constant.GlobalConstant;
import feign.Logger;
import feign.RequestInterceptor;
import org.slf4j.MDC;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class FeignClientConfiguration {
    @Bean
    public RequestInterceptor feignRequestInterceptor() {
        return template -> {
            template.header(GlobalConstant.HEADER_TRACE_ID, MDC.get(GlobalConstant.TRACE_ID));
        };
    }

    @Bean
    Logger.Level feignLoggerLevel() {
        return Logger.Level.FULL;
    }
}
