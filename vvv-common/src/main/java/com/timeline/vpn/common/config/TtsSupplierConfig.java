package com.timeline.vpn.common.config;

import lombok.Data;
import lombok.ToString;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.cloud.context.config.annotation.RefreshScope;
import org.springframework.context.annotation.Configuration;

import java.util.HashMap;
import java.util.Map;

@Data
@Slf4j
@Configuration
@ConfigurationProperties(prefix = "tts")
@RefreshScope
@ToString
public class TtsSupplierConfig {
    private String active;
    private Map<String, TtsVolcengineConfig> supplier = new HashMap<>();

    public TtsVolcengineConfig getActiveConfig() {
        return supplier.get(active);
    }
}
