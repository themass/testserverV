package com.timeline.vpn.common.service.impl.pubsub;

import com.timeline.vpn.common.service.IMsgReceiverListener;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.listener.RedisMessageListenerContainer;
import org.springframework.data.redis.listener.adapter.MessageListenerAdapter;

import java.util.List;

@Configuration
public class RedisSubListenerConfig {
    @Bean
    RedisMessageListenerContainer container(RedisConnectionFactory connectionFactory) {
        RedisMessageListenerContainer container = new RedisMessageListenerContainer();
        container.setConnectionFactory(connectionFactory);
        return container;
    }

    @Bean
    MessageListenerAdapter listenerAdapter(DefMsgRedisReceiver defMsgRedisReceiver) {
        return new MessageListenerAdapter(defMsgRedisReceiver, "receiveMessage");
    }

    @Bean
    DefMsgRedisReceiver msgRedisReceiver(List<IMsgReceiverListener> receiverListeners) {
        return new DefMsgRedisReceiver(receiverListeners);
    }
}