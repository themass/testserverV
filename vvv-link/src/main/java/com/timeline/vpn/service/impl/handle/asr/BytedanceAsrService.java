package com.timeline.vpn.service.impl.handle.asr;

import com.timeline.vpn.common.utils.Base64Util;
import com.timeline.vpn.model.form.AsrContentForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.AsrResponseVo;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.service.impl.handle.asr.bean.AsrResponse;
import com.timeline.vpn.service.impl.handle.asr.bean.BytedanceAsrClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.util.Arrays;
import java.util.Base64;
@Service
public class BytedanceAsrService extends BaseAsrHandleProxy {
    private static final Logger logger = LoggerFactory.getLogger(BytedanceAsrService.class);
    String appid = "4319026663";  // 项目的 appid
    String token = "YJYBl-jGgkv-AZfQrwObHWfbwa5w3aAX";  // 项目的 token
    String cluster = "volcengine_input_common";  // 请求的集群
    String audio_format = "raw";  // wav 或者 mp3, 根据音频类型设置

    @Override
    public AsrResponseVo asrHandler(BaseQuery baseQuery, AsrContentForm asrContentForm) throws Exception {

        BytedanceAsrClient asr_client = null;
        try {
            asr_client = BytedanceAsrClient.build();
            asr_client.setAppid(appid);
            asr_client.setToken(token);
            asr_client.setCluster(cluster);
            asr_client.setFormat(audio_format);
            asr_client.setShow_utterances(true);
            asr_client.asr_sync_connect();

            ByteArrayInputStream byteArrayInputStream = new ByteArrayInputStream(Base64Util.decodeBase64(asrContentForm.getContent()));
            byte[] b = new byte[16000];
            int len = 0;
            int count = 0;
            AsrResponse asr_response = new AsrResponse();
            while ((len = byteArrayInputStream.read(b)) > 0) {
                count += 1;
                logger.info("send data pack length: {}, count {}, is_last {}", len, count, byteArrayInputStream.available() == 0);
                asr_response = asr_client.asr_send(Arrays.copyOfRange(b, 0, len), byteArrayInputStream.available() == 0);
            }

            // get asr text
//            AsrResponse response = asr_client.getAsrResponse();
            AsrResponseVo asrResponseVo = new AsrResponseVo();
            StringBuilder sb = new StringBuilder();
            for (AsrResponse.Result result: asr_response.getResult()) {
                logger.info(result.getText());
                sb.append(result.getText());
            }
            asrResponseVo.setProd("bytedance_asr");
            asrResponseVo.setText(sb.toString());
            return asrResponseVo;
        } catch (Exception e) {
            logger.error("",e);
        } finally {
            if (asr_client != null) {
                asr_client.asr_close();
            }
        }
        return new AsrResponseVo();
    }



    @Override
    public boolean support(Integer t) {
        return t<5;
    }
}
