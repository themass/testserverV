package com.timeline.vpn.service.impl.handle.tts;

import com.alibaba.dashscope.audio.tts.SpeechSynthesisAudioFormat;
import com.alibaba.dashscope.audio.tts.SpeechSynthesisParam;
import com.alibaba.dashscope.audio.tts.SpeechSynthesizer;
import com.timeline.vpn.common.annotation.MethodTimed;
import com.timeline.vpn.common.constant.GlobalConstant;
import com.timeline.vpn.common.exception.BusinessException;
import com.timeline.vpn.model.form.AsrContentForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.TtsResponseVo;
import com.timeline.vpn.service.impl.handle.tts.dto.TtsConfig;
import com.timeline.vpn.service.impl.handle.tts.dto.TtsVolcResponse;
import com.timeline.vpn.common.utils.Base64Util;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.pool2.impl.GenericObjectPool;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.nio.ByteBuffer;
import java.util.UUID;

@Service("aliTtsCloneService")
@Slf4j
@MethodTimed
public class AliTtsCloneServiceImpl extends BaseTtsHandleProxy {
    @Resource(name = "aliCloneGenericObjectPool")
    private GenericObjectPool<SpeechSynthesizer> aliCloneGenericObjectPool;
    private static TtsConfig ttsConfig = new TtsConfig();
    static {
        ttsConfig.setAppid("");
        ttsConfig.setTextType("plain");
        ttsConfig.setEncoding("wav");
        ttsConfig.setSampleRate(16000);
        ttsConfig.setPitchRatio(10);
        ttsConfig.setSpeedRatio(1.2f);
        ttsConfig.setUid("sambert-encvtonem-ft-202406202241-c830");

    }
    @Override
    public TtsResponseVo textToVideo(BaseQuery baseQuery, AsrContentForm chatContentForm){

        String text = chatContentForm.getContent();
        if (GlobalConstant.SSML.equals(ttsConfig.getTextType())) { //ssml协议
            text = textToSSML(chatContentForm.getContent());
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
            TtsResponseVo response = new TtsResponseVo();
            response.setData(Base64Util.encodeBase64(audio.array()));
            response.setId(chatContentForm.getId());
            response.setLang(baseQuery.getAppInfo().getLang());
            response.setFileName(baseQuery.getUser().getName()+"_"+ UUID.randomUUID()+".wav");
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

    @Override
    public boolean support(Integer integer) {
        return false;
    }
}