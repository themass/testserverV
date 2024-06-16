package com.timeline.vpn.common.service;

import com.timeline.vpn.common.service.impl.pubsub.dto.MsgDto;

/**
 * @Author： liguoqing
 * @Date： 2024/4/19 19:26
 * @Describe： 用户消息处理服务，需要继承这个接口
 */
public interface IMsgReceiverListener {
    public void receiveMessage(MsgDto message);
}
