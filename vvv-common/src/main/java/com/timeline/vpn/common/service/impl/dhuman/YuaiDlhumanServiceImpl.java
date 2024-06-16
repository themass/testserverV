package com.timeline.vpn.common.service.impl.dhuman;

import com.timeline.vpn.common.annotation.MethodTimed;
import com.timeline.vpn.common.config.DhumanConfig;
import com.timeline.vpn.common.exception.DHumanRuntimeException;
import com.timeline.vpn.common.service.impl.dhuman.dto.DHCreateParam;
import com.timeline.vpn.common.service.impl.dhuman.dto.DHSendMessageParam;
import com.timeline.vpn.common.service.impl.dhuman.dto.DHSendMessageResponse;
import com.timeline.vpn.common.service.impl.dhuman.dto.SessionResponse;
import com.timeline.vpn.common.service.impl.dhuman.dto.yuai.*;
import com.timeline.vpn.common.utils.Base64Util;
import com.timeline.vpn.common.utils.HttpCommonUtil;
import lombok.extern.slf4j.Slf4j;
import org.apache.hc.client5.http.impl.classic.CloseableHttpResponse;
import org.apache.hc.core5.http.io.entity.EntityUtils;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;

@Slf4j
@Service("yuaiDlhumanService")
@MethodTimed
public class YuaiDlhumanServiceImpl implements YuaiDhumanService {

    private static String COMMAND_KEY = "sequence_id:%s";
    @Resource
    private DhumanConfig dhumanConfig;
    @Resource
    private StringRedisTemplate stringRedisTemplate;

    @Resource
    private YuaiSugarApi yuaiSugarApi;
    private static String sourceHeader = "ai_lesson";

    @Override
    public SessionResponse createLiveRoom(DHCreateParam dhCreateParam) {
        YuaiCreateRequst yuaiCreateRequst = YuaiCreateRequst.builder().
                roomID(dhCreateParam.getRoomId()).
                token(dhCreateParam.getToken()).
                userID(dhCreateParam.getUserId()).
                digitalID(dhumanConfig.getCurrentConfig().getDigitalID()).
                callback(dhumanConfig.getCurrentConfig().getCallBackUrl()).
                build();
        YuaiResponse response = yuaiSugarApi.createLiveRoom(sourceHeader, yuaiCreateRequst);
        log.info("数字人 createLiveRoom：{}", response);
        if (response.isSuccess()) {
            return SessionResponse.builder().sessionId(response.getDigitalLiveID()).build();
        } else {
            log.error("数字人 创建直播间失败：" + response.getStatus());
            throw new DHumanRuntimeException(response.getStatus());
        }
    }

    @Override
    public Boolean statLiveRoom(DHCreateParam dhCreateParam) {
        return true;
//        YuaiCommandRequst yuaiCreateRequst = YuaiCommandRequst.builder().
//                digitalLiveID(dhumanConfig.getCurrentConfig().getDigitalID()).
//                build();
//        YuaiStatResponse response = yuaiSugarApi.queryDigitalStat(sourceHeader, yuaiCreateRequst);
//        return "in-used".equals(response.getResult().get("digitalStatus"));
    }

    @Override
    public Boolean startLive(DHCreateParam dhCreateParam) {
        YuaiCommandRequst yuaiCommandRequst = YuaiCommandRequst.builder().
                digitalLiveID(dhCreateParam.getSessionId()).
                token(dhCreateParam.getToken()).
                roomID(dhCreateParam.getRoomId()).
                build();
        YuaiResponse response = yuaiSugarApi.startLive(sourceHeader, yuaiCommandRequst);
        log.info("数字人 startLive：{}", response);
        if (response.isSuccess()) {
            return true;
        } else {
            log.error("数字人 开启直播间失败：" + response.getStatus());
            throw new DHumanRuntimeException(response.getStatus());
        }
    }


    @Override
    public Boolean stopLive(DHCreateParam dhCreateParam) {
        YuaiCommandRequst yuaiCommandRequst = YuaiCommandRequst.builder().
                digitalLiveID(dhCreateParam.getSessionId()).
                roomID(dhCreateParam.getRoomId()).
                build();
        YuaiResponse response = yuaiSugarApi.stopLive(sourceHeader, yuaiCommandRequst);
        log.info("数字人 stopLive：{}", response);
        return true;
    }

    @Override
    public DHSendMessageResponse commandQueue(DHSendMessageParam dhSendMessageParam) {
        String key = String.format(COMMAND_KEY, dhSendMessageParam.getSessionId());
        long seqId = stringRedisTemplate.opsForValue().increment(key);
        YuaiResponse yuaiResponse = null;
        if (DHSendMessageParam.ProtocolEnum.BINARY.equals(dhSendMessageParam.getProtocol())) {
            //tts之后的二进制文件
            YuaiQueueAudioRequest audioRequest = YuaiQueueAudioRequest.builder().
                    digitalLiveID(dhSendMessageParam.getSessionId()).
                    sequenceID(seqId).
                    audio(dhSendMessageParam.getContext()).
                    build();
            yuaiResponse = yuaiSugarApi.commandQueueAudio(sourceHeader, audioRequest);

        } else if (DHSendMessageParam.ProtocolEnum.HTTP.equals(dhSendMessageParam.getProtocol())) {
            //http文件，下载下来，传给数字人
            try {
                log.info("下载文件："+dhSendMessageParam.getContext());
                CloseableHttpResponse httpResponse = HttpCommonUtil.sendGet(dhSendMessageParam.getContext(), null);
                byte[] audioData = EntityUtils.toByteArray(httpResponse.getEntity());
                EntityUtils.consume(httpResponse.getEntity());
                YuaiQueueAudioRequest audioRequest = YuaiQueueAudioRequest.builder().
                        digitalLiveID(dhSendMessageParam.getSessionId()).
                        sequenceID(seqId).
                        audio(Base64Util.encodeBase64(audioData)).
                        build();
                yuaiResponse = yuaiSugarApi.commandQueueAudio(sourceHeader, audioRequest);
            } catch (Exception e) {
                log.error("下载音频文件失败："+dhSendMessageParam.getContext(), e);
            }
        }else{
            //文本格式的暂时不支持
            log.error("暂时不支持 text格式："+dhSendMessageParam.getContext());
            YuaiQueueTextRequest audioRequest = YuaiQueueTextRequest.builder().
                    sequenceID(seqId).
                    digitalLiveID(dhSendMessageParam.getSessionId()).
                    text(YuaiQueueTextRequest.Text.builder().text(dhSendMessageParam.getContext()).build()).
                    build();
            yuaiResponse = yuaiSugarApi.commandQueueText(sourceHeader, audioRequest);
        }
        log.info("数字人 commandQueue：{}", yuaiResponse);
        return DHSendMessageResponse.builder().commandTraceId(String.valueOf(yuaiResponse.getSequenceID())).build();
    }

    @Override
    public Boolean heartbeat(String sessionId) {
        return true;
    }

}