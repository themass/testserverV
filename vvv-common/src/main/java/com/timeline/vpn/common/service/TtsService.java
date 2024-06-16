package com.timeline.vpn.common.service;

import com.timeline.vpn.common.service.impl.tts.dto.TtsVolcResponse;

import java.io.UnsupportedEncodingException;

/**
 * @Author： liguoqing
 * @Date： 2024/4/11 23:05
 * @Describe：
 */
public interface TtsService {
    public TtsVolcResponse textToVideo(String fileName, String text);

    public String textToSSML(String text) throws UnsupportedEncodingException;
}
