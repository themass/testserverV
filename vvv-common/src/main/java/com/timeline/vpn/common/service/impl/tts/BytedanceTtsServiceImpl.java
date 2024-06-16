package com.timeline.vpn.common.service.impl.tts;

import com.timeline.vpn.common.annotation.MethodTimed;
import com.timeline.vpn.common.config.TtsSupplierConfig;
import com.timeline.vpn.common.config.TtsVolcengineConfig;
import com.timeline.vpn.common.constant.GlobalConstant;
import com.timeline.vpn.common.exception.BusinessException;
import com.timeline.vpn.common.service.TtsService;
import com.timeline.vpn.common.service.impl.tts.dto.BytedanceTtsRequest;
import com.timeline.vpn.common.service.impl.tts.dto.TtsConfig;
import com.timeline.vpn.common.service.impl.tts.dto.TtsVolcResponse;
import com.timeline.vpn.common.utils.JacksonJsonUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

/**
 * @Author： liguoqing
 * @Date： 2024/4/15 11:22
 * @Describe：
 */
@Service("bytedanceTtsService")
@Slf4j
@MethodTimed
public class BytedanceTtsServiceImpl implements TtsService {
    @Autowired
    private BytedanceOpenSpeechApi bytedanceOpenSpeechApi;
    @Autowired
    private TtsSupplierConfig ttSsupplierConfig;
    private static int VOLCENGINE_SUCCESS = 3000;

    @Override
    public TtsVolcResponse textToVideo(String name, String text) {

        TtsVolcengineConfig ttsVolcengineConfig = ttSsupplierConfig.getActiveConfig();
        TtsConfig ttsConfig = ttsVolcengineConfig.getActiveConfig();
        BytedanceTtsRequest bytedanceTtsRequest = new BytedanceTtsRequest();
        bytedanceTtsRequest.getUser().setUid(ttsConfig.getUid());
        bytedanceTtsRequest.getApp().setAppid(ttsConfig.getAppid());
        bytedanceTtsRequest.getApp().setCluster(ttsConfig.getCluster());
        bytedanceTtsRequest.getApp().setToken(ttsConfig.getaKey());

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
        log.info("tts 厂商：{}; 声音:{}; name:{}; 请求：{}", ttSsupplierConfig.getActive(), ttsVolcengineConfig.getActive(), name, text);
        log.info(JacksonJsonUtil.toJsonStr(bytedanceTtsRequest));
        TtsVolcResponse response = bytedanceOpenSpeechApi.getTts("Bearer;" + bytedanceTtsRequest.getToken(), bytedanceTtsRequest);
        log.info("tts 厂商：{}; 声音:{}; name:{}; 返回值：{}", ttSsupplierConfig.getActive(), ttsVolcengineConfig.getActive(), name, response.getCode());
        if (VOLCENGINE_SUCCESS != response.getCode()) {
            throw new BusinessException("字节语音合成失败");
        }
        return response;
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
}
