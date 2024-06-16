package com.timeline.vpn.common.service.impl.tts;

import com.timeline.vpn.common.annotation.MethodTimed;
import com.timeline.vpn.common.config.OssConfig;
import com.timeline.vpn.common.config.TtsSupplierConfig;
import com.timeline.vpn.common.exception.BusinessException;
import com.timeline.vpn.common.service.OssService;
import com.timeline.vpn.common.service.TtsService;
import com.timeline.vpn.common.service.impl.tts.dto.OssRequest;
import com.timeline.vpn.common.service.impl.tts.dto.TtsVolcResponse;
import com.timeline.vpn.common.utils.Base64Util;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Service;

import java.util.Map;

/**
 * @Author： liguoqing
 * @Date： 2024/4/11 23:10
 * @Describe：
 */
@Service
@Slf4j
@MethodTimed
@Primary
public class TtxServiceImpl implements TtsService {

    private int MAX_COUNT = 3;
    @Autowired
    private TtsSupplierConfig ttSsupplierConfig;
    @Autowired
    private Map<String, TtsService> ttsServiceMap;
    @Autowired
    private OssService ossService;
    @Autowired
    private OssConfig ossConfig;


    @Override
    public TtsVolcResponse textToVideo(String name, String text) {
        int count = 0;
        while(count<MAX_COUNT) {
            try {
                TtsVolcResponse response = ttsServiceMap.get(ttSsupplierConfig.getActive()).textToVideo(name, text);
                OssRequest ossRequest = OssRequest.builder().data(Base64Util.decodeBase64(response.getData())).name(name).build();
                ossService.putObjToOss(ossRequest);
                String cdnAddress = ossConfig.getCdnAddrPref() + ossConfig.getDir() + ossRequest.getName();
                response.setCdnUrl(cdnAddress);
                return response;
            }catch (Exception e){
                count++;
                log.error("合成语音出错，重试一次："+count+"/"+MAX_COUNT);
            }
        }
        throw new BusinessException("语音合成失败超过最大值");
    }

    @Override
    public String textToSSML(String text) {
        return null;
    }
}
