package com.timeline.vpn.service.impl.handle.tts;

import com.timeline.vpn.common.annotation.MethodTimed;
import com.timeline.vpn.common.exception.BusinessException;
import com.timeline.vpn.model.form.AsrContentForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.TtsResponseVo;
import com.timeline.vpn.service.impl.handle.tts.dto.ElevenlabsTtsRequest;
import com.timeline.vpn.service.impl.handle.tts.dto.TtsConfig;
import com.timeline.vpn.service.impl.handle.tts.dto.TtsVolcResponse;
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
import java.util.UUID;

@Service("elevenlabsTtsCloneService")
@Slf4j
@MethodTimed
public class ElevenlabsTtsServiceImpl extends BaseTtsHandleProxy {
    private static TtsConfig ttsConfig = new TtsConfig();
    static {
        ttsConfig.setAppid("f2a201660d43c4e82b1c3fb45835114a");
        ttsConfig.setEncoding("wav");
        ttsConfig.setSampleRate(16000);
        ttsConfig.setUid("eleven_monolingual_v1");
        ttsConfig.setUrl("https://api.elevenlabs.io/v1/text-to-speech/PQRgQLtPkf3dvyEMYpQw");
    }
    @Override
    public TtsResponseVo textToVideo(BaseQuery baseQuery, AsrContentForm asrContentForm){
        String name = baseQuery.getUser().getName()+"_"+ UUID.randomUUID()+".wav";
        String text = asrContentForm.getContent();
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
            TtsResponseVo ttsResponseVo = new TtsResponseVo();
            ttsResponseVo.setId(asrContentForm.getId());
            ttsResponseVo.setLang(baseQuery.getAppInfo().getLang());
            ttsResponseVo.setFileName(name);
            ttsResponseVo.setData(Base64Util.encodeBase64(audioData));
            return ttsResponseVo;
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

    @Override
    public boolean support(Integer integer) {
        return false;
    }
}