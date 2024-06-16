package com.timeline.vpn.common.utils;

import org.springframework.context.ApplicationContext;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class SpringUtils {

    private static ApplicationContext applicationContext;

    public SpringUtils(ApplicationContext applicationContext) {
        SpringUtils.applicationContext = applicationContext;
    }

    public static <T> T getBean(Class<T> requiredType) {
        return applicationContext.getBean(requiredType);
    }

    public static <T> Map<String, T> getBeansOfType(Class<T> requiredType) {
        return applicationContext.getBeansOfType(requiredType);
    }

    public static StringRedisTemplate getStringRedisTemplate() {
        return getBean(StringRedisTemplate.class);
    }

}
