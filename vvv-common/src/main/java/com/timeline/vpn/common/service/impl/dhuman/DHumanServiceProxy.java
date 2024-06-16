package com.timeline.vpn.common.service.impl.dhuman;

import com.timeline.vpn.common.annotation.MethodTimed;
import com.timeline.vpn.common.config.DhumanConfig;
import com.timeline.vpn.common.service.DHumanService;
import com.timeline.vpn.common.service.TtsService;
import com.timeline.vpn.common.service.impl.dhuman.dto.DHCreateParam;
import com.timeline.vpn.common.service.impl.dhuman.dto.DHSendMessageParam;
import com.timeline.vpn.common.service.impl.dhuman.dto.DHSendMessageResponse;
import com.timeline.vpn.common.service.impl.dhuman.dto.SessionResponse;
import com.timeline.vpn.common.service.impl.tts.dto.TtsVolcResponse;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Primary;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.time.Duration;
import java.util.UUID;

/**
 * @Author： liguoqing
 * @Date： 2024/4/2 10:19
 * @Describe：
 */
@Primary
@Service
@Slf4j
@MethodTimed
public class DHumanServiceProxy implements DHumanService {
    @Resource(name = "yuaiDlhumanService")
    private YuaiDhumanService yuaiDhumanService;
    @Resource(name = "mockDlhumanService")
    private YuaiDhumanService mockYuaiDhumanService;
    @Autowired
    private DhumanConfig dhumanConfig;
    @Autowired
    private StringRedisTemplate stringRedisTemplate;
    @Autowired
    private TtsService ttsService;
    private static final String USE_VOICE = "VOICE";
    private static final String NAME = "%s/%s_%s.wav";
    public static final String DH_COST_MONITER = "dhuman_msg_cost:%s";
    private YuaiDhumanService getTarget() {
        if (dhumanConfig.isMock()) {
            return mockYuaiDhumanService;
        }
        return yuaiDhumanService;
    }

    @Override
    public SessionResponse createLiveRoom(DHCreateParam dhCreateParam) {
        return getTarget().createLiveRoom(dhCreateParam);
    }

    @Override
    public Boolean startLive(DHCreateParam dhCreateParam) {
        return getTarget().startLive(dhCreateParam);
    }

    @Override
    public boolean statLive(DHCreateParam dhCreateParam) {
        return getTarget().statLiveRoom(dhCreateParam);
    }

    @Override
    public Boolean stopLive(DHCreateParam sessionId) {
        try {
            return getTarget().stopLive(sessionId);
        }catch (Exception e){
            log.error("数字人关闭异常：",e);
        }
        return false;

    }

    @Override
    @MethodTimed
    public DHSendMessageResponse commandQueue(DHSendMessageParam dhSendMessageParam) {
        if (StringUtils.isEmpty(dhSendMessageParam.getContext())) {
            log.error("发送数字人文本不允许为空，dhSendMessageParam:{}", dhSendMessageParam);
            return null;
        }
        if(dhSendMessageParam.getContext().startsWith("http")){
            dhSendMessageParam.setProtocol(DHSendMessageParam.ProtocolEnum.HTTP);
        }else{
            dhSendMessageParam.setProtocol(DHSendMessageParam.ProtocolEnum.TEXT);
        }
        try {
            if (USE_VOICE.equals(dhumanConfig.getUse()) && !dhSendMessageParam.getContext().startsWith("http")) {
                this.txtToAudio(dhSendMessageParam);
                dhSendMessageParam.setProtocol(DHSendMessageParam.ProtocolEnum.BINARY);
            }
        } catch (Exception e) {
            log.info("error数据：{}", dhSendMessageParam);
            log.error("tts 失败，继续使用txt", e);
        }
        DHSendMessageResponse response;
        try {
            response =  getTarget().commandQueue(dhSendMessageParam);
            stringRedisTemplate.opsForValue().set(getMonitorKey(response.getCommandTraceId()), String.valueOf(System.currentTimeMillis()), Duration.ofHours(1));
            return response;
        } catch (Exception e) {
            log.info("error数据：{}", dhSendMessageParam);
            log.error("数字commandQueue失败", e);
        }
        return null;
    }

    private DHSendMessageParam txtToAudio(DHSendMessageParam dhSendMessageParam) {
        String fileName = String.format(NAME, dhSendMessageParam.getLessonId(), dhSendMessageParam.getUserId(), UUID.randomUUID().toString());
        TtsVolcResponse response = ttsService.textToVideo(fileName, dhSendMessageParam.getContext());
        log.info("tts转换 txt:{}, url:{}", dhSendMessageParam.getContext(), response.getCdnUrl());
        dhSendMessageParam.setContext(response.getData());
        return dhSendMessageParam;
    }

    @Async("dhumanHeartbeatExecutor")
    @Override
    public void heartbeat(String sessionId) {
        softSugarHeartbeat(sessionId);
    }

    @Async("dhumanHeartbeatExecutor")
    @Override
    public void monitorCost(String traceId) {
        String startStr = stringRedisTemplate.opsForValue().get(getMonitorKey(traceId));
        if(StringUtils.isNotBlank(startStr)){
           Long start = Long.parseLong(startStr);
           long cost = System.currentTimeMillis() - start;
           //TODO 埋点 监控
        }

    }

    private void softSugarHeartbeat(String sessionId) {
        try {
            log.debug("user {} softSugarHeartbeat...", sessionId);
            getTarget().heartbeat(sessionId);
        } catch (Exception e) {
            log.error("user {} softSugarHeartbeat error...", sessionId, e);
        }
    }
    public static String getMonitorKey(String traceId){
        return String.format(DH_COST_MONITER,traceId);
    }
}
