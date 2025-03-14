package com.timeline.vpn.service.impl.handle.tts;

import com.timeline.vpn.common.annotation.MethodTimed;
import com.timeline.vpn.common.constant.GlobalConstant;
import com.timeline.vpn.common.exception.BusinessException;
import com.timeline.vpn.common.utils.Base64Util;
import com.timeline.vpn.model.form.AsrContentForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.TtsResponseVo;
import com.timeline.vpn.service.impl.handle.tts.dto.BytedanceTtsRequest;
import com.timeline.vpn.service.impl.handle.tts.dto.TtsConfig;
import com.timeline.vpn.service.impl.handle.tts.dto.TtsVolcResponse;
import com.timeline.vpn.common.utils.JacksonJsonUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.UUID;

/**
 * @Author： liguoqing
 * @Date： 2024/4/15 11:22
 * @Describe：
 */
@Service("bytedanceTtsService")
@Slf4j
@MethodTimed
public class BytedanceTtsServiceImpl extends BaseTtsHandleProxy {
    @Autowired
    private BytedanceOpenSpeechApi bytedanceOpenSpeechApi;
    private static int VOLCENGINE_SUCCESS = 3000;
    private static TtsConfig ttsConfig = new TtsConfig();
    static {
        ttsConfig.setAppid("4319026663");
        ttsConfig.setTextType("plain");
        ttsConfig.setEncoding("wav");
        ttsConfig.setSampleRate(48000);
        ttsConfig.setUid("388808087185088");
        ttsConfig.setVoiceType("BV001_streaming");
        ttsConfig.setCluster("volcano_tts");
        ttsConfig.setToken("YJYBl-jGgkv-AZfQrwObHWfbwa5w3aAX");
        ttsConfig.setEmotion("happy");
    }
    @Override
    public TtsResponseVo textToVideo(BaseQuery baseQuery, AsrContentForm asrContentForm){
        String name = baseQuery.getUser().getName()+"_"+ UUID.randomUUID()+".wav";
        String text = asrContentForm.getContent();
        BytedanceTtsRequest bytedanceTtsRequest = new BytedanceTtsRequest();
        bytedanceTtsRequest.getUser().setUid(ttsConfig.getUid());
        bytedanceTtsRequest.getApp().setAppid(ttsConfig.getAppid());
        bytedanceTtsRequest.getApp().setCluster(ttsConfig.getCluster());
        bytedanceTtsRequest.getApp().setToken(ttsConfig.getAccessKey());

        bytedanceTtsRequest.getAudio().setEmotion(ttsConfig.getEmotion());
        bytedanceTtsRequest.getAudio().setEncoding(ttsConfig.getEncoding());
        bytedanceTtsRequest.getAudio().setPitch_ratio(ttsConfig.getPitchRatio());
        bytedanceTtsRequest.getAudio().setSample_rate(ttsConfig.getSampleRate());
        bytedanceTtsRequest.getAudio().setSpeed_ratio(ttsConfig.getSpeedRatio());
        bytedanceTtsRequest.getAudio().setVoice_type(ttsConfig.getVoiceType());
        bytedanceTtsRequest.getAudio().setVolume_ratio(ttsConfig.getVolumeRatio());

        bytedanceTtsRequest.getRequest().setOperation(ttsConfig.getOperation());
        bytedanceTtsRequest.getRequest().setReqid(name);
        bytedanceTtsRequest.getRequest().setText_type(ttsConfig.getTextType());
        bytedanceTtsRequest.getRequest().setText(text);
        bytedanceTtsRequest.setToken(ttsConfig.getToken());
        if (GlobalConstant.SSML.equals(ttsConfig.getTextType())) { //ssml协议
            text = textToSSML(text);
        }
        if(text.length()>1024){
            throw new BusinessException("字节语音合成失败 -- 字符太长"+text.length());
        }
        log.info("tts合成请求："+JacksonJsonUtil.toJsonStr(bytedanceTtsRequest));
        TtsVolcResponse response = bytedanceOpenSpeechApi.getTts("Bearer;" + bytedanceTtsRequest.getToken(), bytedanceTtsRequest);
        if (VOLCENGINE_SUCCESS != response.getCode()) {
            throw new BusinessException("字节语音合成失败");
        }
        TtsResponseVo ttsResponseVo = new TtsResponseVo();
        ttsResponseVo.setId(asrContentForm.getId());
        ttsResponseVo.setLang(baseQuery.getAppInfo().getLang());
        ttsResponseVo.setFileName(name);
        ttsResponseVo.setData(response.getData());
        return ttsResponseVo;
    }

    @Override
    public String textToSSML(String text) {
        String ssmltemp = "<speak>  \n" +
                "  <prosody volume=\"1.2\" pitch=\"1.0\" speed=\"1.0\">\n" +
                "    <tobi phrase_accent=\"H-\" boundary_tone=\"L%\">\n" +
                "#{mytext}\n" +
                "    </tobi>\n" +
                "  </prosody>\n" +
                "</speak>";
        return ssmltemp.replace("#{mytext}", text);
    }

    @Override
    public boolean support(Integer integer) {
        return true;
    }
}
