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
public class ElevenlabsTtsRequest {
    @JsonProperty("model_id")
    private String modelId;
    @JsonProperty("voice_settings")
    private VoiceSettings voiceSettings;
    private String text;
    private float seed;

    @Data
    public static class VoiceSettings {
        private float stability;
        @JsonProperty("similarity_boost")
        private int similarityBoost;
        private int style;
        @JsonProperty("use_speaker_boost")
        private boolean useSpeakerBoost;

    }
}
