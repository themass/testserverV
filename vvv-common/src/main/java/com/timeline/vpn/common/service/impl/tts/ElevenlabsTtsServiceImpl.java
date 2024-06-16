package com.timeline.vpn.common.service.impl.tts;

import com.timeline.vpn.common.annotation.MethodTimed;
import com.timeline.vpn.common.config.TtsSupplierConfig;
import com.timeline.vpn.common.config.TtsVolcengineConfig;
import com.timeline.vpn.common.exception.BusinessException;
import com.timeline.vpn.common.service.TtsService;
import com.timeline.vpn.common.service.impl.tts.dto.ElevenlabsTtsRequest;
import com.timeline.vpn.common.service.impl.tts.dto.TtsConfig;
import com.timeline.vpn.common.service.impl.tts.dto.TtsVolcResponse;
import com.timeline.vpn.common.utils.Base64Util;
import com.timeline.vpn.common.utils.HttpCommonUtil;
import com.timeline.vpn.common.utils.JacksonJsonUtil;
import lombok.extern.slf4j.Slf4j;
import org.apache.hc.client5.http.impl.classic.CloseableHttpResponse;
import org.apache.hc.core5.http.ContentType;
import org.apache.hc.core5.http.io.entity.EntityUtils;
import org.apache.hc.core5.http.io.entity.StringEntity;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Service("elevenlabsTtsCloneService")
@Slf4j
@MethodTimed
public class ElevenlabsTtsServiceImpl implements TtsService {
    @Autowired
    private TtsSupplierConfig ttSsupplierConfig;

    @Override
    public TtsVolcResponse textToVideo(String name, String text) {
        TtsVolcengineConfig ttsVolcengineConfig = ttSsupplierConfig.getActiveConfig();
        TtsConfig ttsConfig = ttsVolcengineConfig.getActiveConfig();
        ElevenlabsTtsRequest request = new ElevenlabsTtsRequest();
        request.setSeed(ttsConfig.getSpeedRatio());
        request.setModelId(ttsConfig.getUid());
        request.setText(text);
        ElevenlabsTtsRequest.VoiceSettings voiceSettings = new ElevenlabsTtsRequest.VoiceSettings();
//        voiceSettings.setStyle(0);
        voiceSettings.setStability(0.8f);
        voiceSettings.setSimilarityBoost(1);
        voiceSettings.setUseSpeakerBoost(true);
        request.setVoiceSettings(voiceSettings);
        Map<String, String> header = new HashMap<>();
        header.put("xi-api-key", ttsConfig.getAppid());
        header.put("Content-Type", ContentType.APPLICATION_JSON.getMimeType());
        try {
            CloseableHttpResponse httpResponse = HttpCommonUtil.sendPostWithEntity(ttsConfig.getUrl(), new StringEntity(JacksonJsonUtil.toJsonStr(request), ContentType.APPLICATION_JSON), header);
            byte[] audioData = EntityUtils.toByteArray(httpResponse.getEntity());
            EntityUtils.consume(httpResponse.getEntity());
            TtsVolcResponse response = new TtsVolcResponse();
            response.setData(Base64Util.encodeBase64(audioData));
            return response;
        } catch (Exception e) {
            log.error("elevenlabs语音合成失败", e);
            throw new BusinessException("elevenlabs语音合成失败");
        }
    }

    @Override
    public String textToSSML(String text) {
        String ssmltemp = "<speak>#{mytext}</speak>";
        return ssmltemp.replace("#{mytext}", text);
    }

}