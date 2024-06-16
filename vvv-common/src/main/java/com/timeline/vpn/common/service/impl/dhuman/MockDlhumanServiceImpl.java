package com.timeline.vpn.common.service.impl.dhuman;

import com.timeline.vpn.common.annotation.MethodTimed;
import com.timeline.vpn.common.service.impl.dhuman.dto.DHCreateParam;
import com.timeline.vpn.common.service.impl.dhuman.dto.DHSendMessageParam;
import com.timeline.vpn.common.service.impl.dhuman.dto.DHSendMessageResponse;
import com.timeline.vpn.common.service.impl.dhuman.dto.SessionResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;

@Slf4j
@Service("mockDlhumanService")
@MethodTimed
public class MockDlhumanServiceImpl implements YuaiDhumanService {

    @Resource
    private DhumanCommandbCallackService dhumanCommandbCallackService;

    private static String COMMAND_KEY = "sequence_id:%s";
    @Resource
    private StringRedisTemplate stringRedisTemplate;

    @Override
    public SessionResponse createLiveRoom(DHCreateParam dhCreateParam) {
        dhumanCommandbCallackService.trySubmitMockStartLive("live_1");
        return SessionResponse.builder().sessionId("live_1").status(0).build();
    }

    @Override
    public Boolean statLiveRoom(DHCreateParam dhCreateParam) {
        return true;
    }

    @Override
    public Boolean startLive(DHCreateParam dhCreateParam) {
        return true;
    }


    @Override
    public Boolean stopLive(DHCreateParam dhCreateParam) {
        return true;
    }

    @Override
    public DHSendMessageResponse commandQueue(DHSendMessageParam dhSendMessageParam) {
        String key = String.format(COMMAND_KEY, dhSendMessageParam.getSessionId());
        long seqId = stringRedisTemplate.opsForValue().increment(key);
        dhumanCommandbCallackService.trySubmitMockCallback(dhSendMessageParam.getSessionId(), seqId + "");
        return DHSendMessageResponse.builder().commandTraceId(seqId + "").build();
    }

    @Override
    public Boolean heartbeat(String sessionId) {
        return true;
    }

}