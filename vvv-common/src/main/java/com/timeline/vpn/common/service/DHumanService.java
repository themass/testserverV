package com.timeline.vpn.common.service;

import com.timeline.vpn.common.service.impl.dhuman.dto.DHCreateParam;
import com.timeline.vpn.common.service.impl.dhuman.dto.DHSendMessageParam;
import com.timeline.vpn.common.service.impl.dhuman.dto.DHSendMessageResponse;
import com.timeline.vpn.common.service.impl.dhuman.dto.SessionResponse;

/**
 * @Author： liguoqing
 * @Date： 2024/4/2 10:12
 * @Describe：
 */
public interface DHumanService {


    SessionResponse createLiveRoom(DHCreateParam dhCreateParam);

    Boolean startLive(DHCreateParam dhCreateParam);

    boolean statLive(DHCreateParam dhCreateParam);

    DHSendMessageResponse commandQueue(DHSendMessageParam dhSendMessageParam);

    Boolean stopLive(DHCreateParam dhCreateParam);

    void heartbeat(String sessionId);
    void monitorCost(String traceId);
}
