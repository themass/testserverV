package com.timeline.vpn.service.impl.handle.asr;

import com.timeline.vpn.common.utils.Base64Util;
import com.timeline.vpn.common.utils.HttpCommonUtil;
import com.timeline.vpn.model.chat.SpeechRecognitionResponse;
import com.timeline.vpn.model.form.AsrContentForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.AsrResponseVo;
import com.timeline.vpn.service.impl.handle.asr.bean.AsrResponse;
import com.timeline.vpn.service.impl.handle.asr.bean.BytedanceAsrClient;
import com.timeline.vpn.util.JsonUtil;
import lombok.Data;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.ByteArrayInputStream;
import java.util.Arrays;
import java.util.List;

@Service
public class DeepgramAsrService extends BaseAsrHandleProxy {
    private static final Logger logger = LoggerFactory.getLogger(DeepgramAsrService.class);
    String token = "Token c855a267d26e553c5b8e48f58114e9ad88bd460f";
    String url = "https://api.deepgram.com/v1/listen?model=nova-2-general&smart_format=true";// 项目的 token
    @Override
    public AsrResponseVo asrHandler(BaseQuery baseQuery, AsrContentForm asrContentForm) throws Exception {
        try {
            okhttp3.MediaType mediaType = okhttp3.MediaType.parse("audio/wav");
            okhttp3.RequestBody body = okhttp3.RequestBody.create(mediaType,Base64Util.decodeBase64(asrContentForm.getContent()));
            okhttp3.Request httpRequest = new okhttp3.Request.Builder()
                    .url(url)
                    .addHeader("Authorization", token)
                    .addHeader("Content-Type", "audio/wav")
                    .post(body)
                    .build();
            okhttp3.Response response = httpClient.newCall(httpRequest).execute();
            String res = response.body().string();
            SpeechRecognitionResponse response1 = JsonUtil.readValue(res, SpeechRecognitionResponse.class);
            AsrResponseVo asrResponseVo = new AsrResponseVo();
            LOGGER.info("deepgram asr 识别："+res);
            asrResponseVo.setProd("deepgram_asr");
            if (response1 != null && response1.getResults() != null && response1.getResults().getChannels() != null && response1.getResults().getChannels().size() > 0 && response1.getResults().getChannels().get(0).getAlternatives() != null && response1.getResults().getChannels().get(0).getAlternatives().size() > 0) {
                asrResponseVo.setText(response1.getResults().getChannels().get(0).getAlternatives().get(0).getTranscript());
            }
            return asrResponseVo;
        }catch (Exception e){
            LOGGER.error("", e);
        }
        return  new AsrResponseVo();
    }

    @Override
    public boolean support(Integer t) {
        return false;
    }

}
