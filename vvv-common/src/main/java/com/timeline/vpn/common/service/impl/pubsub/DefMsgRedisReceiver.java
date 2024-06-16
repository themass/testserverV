package com.timeline.vpn.common.service.impl.pubsub;

import com.timeline.vpn.common.service.IMsgReceiverListener;
import com.timeline.vpn.common.service.impl.pubsub.dto.MsgDto;
import com.timeline.vpn.common.utils.JacksonJsonUtil;
import lombok.extern.slf4j.Slf4j;

import java.util.List;

@Slf4j
public class DefMsgRedisReceiver {
    List<IMsgReceiverListener> receiverListeners;

    public DefMsgRedisReceiver(List<IMsgReceiverListener> receiverListeners) {
        this.receiverListeners = receiverListeners;
    }

    public void receiveMessage(String message) {
        //这里是收到通道的消息之后执行的方法
        log.info("订阅消息：{}", message);
        MsgDto dto = JacksonJsonUtil.readValue(message, MsgDto.class);
        for (IMsgReceiverListener listener : receiverListeners) {
            listener.receiveMessage(dto);
        }
    }
}