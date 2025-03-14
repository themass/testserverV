package com.timeline.vpn.service.impl.handle.tts.dto;

import lombok.Data;
import lombok.ToString;

/**
 * @Author： liguoqing
 * @Date： 2024/4/23 10:03
 * @Describe：
 */
@Data
@ToString
public class TtsConfig {
    private String appid;
    private String accessKey;
    private String accessKeySecret;
    private String token;
    private String cluster;
    private String uid;
    private String url;
    private String voiceType;
    private String encoding = "wav";
    private float speedRatio = 1.0F;
    private float volumeRatio = 10.0F;
    private Integer pitchRatio = 1;
    private String emotion = "happy";
    private Integer sampleRate = 16000;
    private String textType = "plain";
    private String operation = "query";
    private String language = "EN";
    private Boolean enableIpa = true;

}
