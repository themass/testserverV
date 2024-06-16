package com.timeline.vpn.common.service.impl.tts.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;

/**
 * @Author： liguoqing
 * @Date： 2024/4/15 19:15
 * @Describe：
 */
@Data
@Slf4j
public class AliTtsRequest {
    private String appkey;
    private String token;
    private String text;
    private String format = "wav";
    private String voice;
    @JsonProperty("sample_rate")
    private Integer sampleRate;
}
