package com.timeline.vpn.common.service.impl.pubsub;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.listener.PatternTopic;
import org.springframework.data.redis.listener.RedisMessageListenerContainer;
import org.springframework.data.redis.listener.adapter.MessageListenerAdapter;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

/**
 * @Author： liguoqing
 * @Date： 2024/4/19 17:16
 * @Describe：
 */
@Service
@Slf4j
public class MsgSubManager {
    @Autowired
    private RedisMessageListenerContainer container;
    @Autowired
    private MessageListenerAdapter messageListenerAdapter;

    public static String PRE = "ailesson.live.";

    @Async("subExec")
    public void subscribeChannel(String roomId) {
        container.addMessageListener(messageListenerAdapter, new PatternTopic(PRE + roomId));
        log.info("订阅用户：{}", roomId);
    }
    @Async("subExec")
    public void unsubscribeChannel(String roomId) {
        container.removeMessageListener(messageListenerAdapter, new PatternTopic(PRE + roomId));
        log.info("取消订阅用户：{}", roomId);
    }

}
