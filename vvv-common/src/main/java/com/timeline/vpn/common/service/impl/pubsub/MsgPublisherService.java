package com.timeline.vpn.common.service.impl.pubsub;

import com.timeline.vpn.common.service.impl.pubsub.dto.MsgDto;
import com.timeline.vpn.common.utils.JacksonJsonUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

/**
 * @Author： liguoqing
 * @Date： 2024/4/19 20:44
 * @Describe：
 */
@Service
@Slf4j
public class MsgPublisherService {
    @Autowired
    private StringRedisTemplate stringRedisTemplate;

    public void sendChannelMsg(String roomId, MsgDto message) {
        log.info("下发消息:{}", JacksonJsonUtil.toJsonStr(message));
        stringRedisTemplate.convertAndSend(MsgSubManager.PRE + roomId, JacksonJsonUtil.toJsonStr(message));
    }
}
