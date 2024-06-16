package com.timeline.vpn.common.service.impl.tts;

import com.alibaba.dashscope.audio.tts.SpeechSynthesisAudioFormat;
import com.alibaba.dashscope.audio.tts.SpeechSynthesisParam;
import com.alibaba.dashscope.audio.tts.SpeechSynthesizer;
import com.timeline.vpn.common.annotation.MethodTimed;
import com.timeline.vpn.common.config.TtsSupplierConfig;
import com.timeline.vpn.common.config.TtsVolcengineConfig;
import com.timeline.vpn.common.constant.GlobalConstant;
import com.timeline.vpn.common.exception.BusinessException;
import com.timeline.vpn.common.service.TtsService;
import com.timeline.vpn.common.service.impl.tts.dto.TtsConfig;
import com.timeline.vpn.common.service.impl.tts.dto.TtsVolcResponse;
import com.timeline.vpn.common.utils.Base64Util;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.pool2.impl.GenericObjectPool;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.nio.ByteBuffer;

@Service("aliTtsCloneService")
@Slf4j
@MethodTimed
public class AliTtsCloneServiceImpl implements TtsService {
    @Resource(name = "aliCloneGenericObjectPool")
    private GenericObjectPool<SpeechSynthesizer> aliCloneGenericObjectPool;

    @Autowired
    private TtsSupplierConfig ttSsupplierConfig;

    @Override
    public TtsVolcResponse textToVideo(String name, String text) {
        TtsVolcengineConfig ttsVolcengineConfig = ttSsupplierConfig.getActiveConfig();
        TtsConfig ttsConfig = ttsVolcengineConfig.getActiveConfig();
        if (GlobalConstant.SSML.equals(ttsConfig.getTextType())) { //ssml协议
            text = textToSSML(text);
        }
        SpeechSynthesisParam param = SpeechSynthesisParam.builder()
                .model(ttsConfig.getUid())
                .text(text)
                .sampleRate(ttsConfig.getSampleRate())
                .format(SpeechSynthesisAudioFormat.WAV)
                .apiKey(ttsConfig.getAppid())
                .build();
        // 调用call方法，传入param参数，获取合成音频
        SpeechSynthesizer synthesizer = null;
        try {
            synthesizer = aliCloneGenericObjectPool.borrowObject();
            ByteBuffer audio = synthesizer.call(param);
            TtsVolcResponse response = new TtsVolcResponse();
            response.setData(Base64Util.encodeBase64(audio.array()));
            return response;
        } catch (Exception e) {
            log.error("合成失败", e);
        } finally {
            if (synthesizer != null) {
                aliCloneGenericObjectPool.returnObject(synthesizer);
            }
        }
        throw new BusinessException("ali-clone语音合成失败");
    }

    @Override
    public String textToSSML(String text) {
        String ssmltemp = "<speak>#{mytext}</speak>";
        return ssmltemp.replace("#{mytext}", text);
    }

}