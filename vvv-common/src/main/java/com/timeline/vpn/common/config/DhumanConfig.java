package com.timeline.vpn.common.config;

import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.HashMap;
import java.util.Map;

@Data
@Slf4j
@Configuration
@ConfigurationProperties(prefix = "dhuman")
public class DhumanConfig {
    private String active; // 用于存储 switch 属性的值
    private Map<String, DhumanProperties> config = new HashMap<>();
    private String use;
    private boolean mock;

    // 定义内部类来表示每种环境的配置
    @Data
    public static class DhumanProperties {
        private String baseUrl;
        private String callBackUrl;
        private String digitalID;
    }

    @Bean
    public DhumanProperties getCurrentConfig() {
        return config.get(active);
    }



}