package com.timeline.vpn.common.service.impl.tts.dto;

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
    private String appKey;
    private String appKeySt;
    private String token;
    private String cluster;
    private String uid;
    private String url;
    private String voiceType;
    private String encoding = "wav";
    private float speedRatio = 1.0f;
    private float volumeRatio = 10;
    private float pitchRatio = 1;
    private String emotion = "happy";
    private Integer sampleRate = 24000;
    private String textType = "plain";
    private String operation = "query";

}
