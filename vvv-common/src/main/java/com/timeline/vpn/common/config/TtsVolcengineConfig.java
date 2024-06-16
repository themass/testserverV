package com.timeline.vpn.common.config;

import com.timeline.vpn.common.service.impl.tts.dto.TtsConfig;
import lombok.Data;
import lombok.ToString;
import lombok.extern.slf4j.Slf4j;

import java.util.HashMap;
import java.util.Map;

@Data
@Slf4j
@ToString
public class TtsVolcengineConfig {
    private String active; // 用于存储 switch 属性的值
    private Map<String, TtsConfig> config = new HashMap<>();

    public TtsConfig getActiveConfig() {
        return config.get(active);
    }
}
