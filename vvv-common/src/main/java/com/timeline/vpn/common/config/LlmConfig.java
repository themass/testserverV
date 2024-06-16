package com.timeline.vpn.common.config;

import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.cloud.context.config.annotation.RefreshScope;
import org.springframework.context.annotation.Configuration;

import java.util.HashMap;
import java.util.Map;

@Data
@Slf4j
@Configuration
@ConfigurationProperties(prefix = "llm")
@RefreshScope
public class LlmConfig {
    private String active; // 用于存储 switch 属性的值
    private String backUp; // 用于存储 failOver ，自动切换大模型
    private Map<String, LlmProperties> config = new HashMap<>();

    @Data
    public static class LlmProperties {
        private String secretKey;
        private String appKey;
        private String endpoint;
        private String host;
        private String region;
        private float temperature;
        private float topP;
        private String modelName;
    }
}
