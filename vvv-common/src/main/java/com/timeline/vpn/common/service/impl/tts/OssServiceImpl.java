package com.timeline.vpn.common.service.impl.tts;

import com.timeline.vpn.common.annotation.MethodTimed;
import com.timeline.vpn.common.config.OssConfig;
import com.timeline.vpn.common.exception.BusinessException;
import com.timeline.vpn.common.service.OssService;
import com.timeline.vpn.common.service.impl.tts.dto.OssRequest;
import com.volcengine.tos.TOSV2;
import com.volcengine.tos.TOSV2ClientBuilder;
import com.volcengine.tos.model.object.PutObjectInput;
import com.volcengine.tos.model.object.PutObjectOutput;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.io.ByteArrayInputStream;

/**
 * @Author： liguoqing
 * @Date： 2024/4/11 21:39
 * @Describe：
 */
@Service
@Slf4j
public class OssServiceImpl implements OssService {
    @Autowired
    private OssConfig ossConfig;

    /**
     * @param request
     * @return cdn地址
     */
    @Override
    @MethodTimed
    @Async("ossPushExecutor")
    public void putObjToOss(OssRequest request) {
        log.info("异步上传音频文件:{}",request.getName());
        TOSV2 tos = new TOSV2ClientBuilder().build(ossConfig.getRegion(), ossConfig.getEndpoint(), ossConfig.getAccessKey(), ossConfig.getSecretKey());
        try {
            byte[] dataInBytes = request.getData();
            ByteArrayInputStream stream = new ByteArrayInputStream(dataInBytes);
            PutObjectInput putObjectInput = new PutObjectInput()
                    .setBucket(ossConfig.getBucketName()).setKey(ossConfig.getDir() + request.getName()).setContent(stream);
            PutObjectOutput output = tos.putObject(putObjectInput);
//            return ossConfig.getCdnAddrPref() + ossConfig.getDir() + request.getName();
//            log.info("put oss name:{}, resp:{}", "https://cdn-hs.yuaiweiwu.com/athena/"+request.getName(), JacksonJsonUtil.toJsonStr(output));
        } catch (Exception e) {
            log.error("", e);
            throw new BusinessException("oss 上传失败: config+" + ossConfig.toString());
        }
    }
}
