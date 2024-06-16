package com.timeline.vpn.web.common.config;

import com.timeline.vpn.web.common.filter.HostFilter;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class FilterConfig {
    @Bean
    public FilterRegistrationBean myFilter() {
        FilterRegistrationBean registration = new FilterRegistrationBean();
        registration.setFilter(new HostFilter());
        registration.addUrlPatterns("*.json");
        registration.setOrder(1);
        return registration;
    }
}