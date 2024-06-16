package com.timeline.vpn.common.service.impl.dhuman;

import com.timeline.vpn.common.service.impl.dhuman.dto.DHCreateParam;
import com.timeline.vpn.common.service.impl.dhuman.dto.DHSendMessageParam;
import com.timeline.vpn.common.service.impl.dhuman.dto.DHSendMessageResponse;
import com.timeline.vpn.common.service.impl.dhuman.dto.SessionResponse;

public interface YuaiDhumanService {

    SessionResponse createLiveRoom(DHCreateParam dhCreateParam);

    Boolean startLive(DHCreateParam dhCreateParam);

    Boolean stopLive(DHCreateParam sessionId);

    /**
     * 检测直播流是否创建完成
     *
     * @param sessionId
     * @return
     */
    Boolean statLiveRoom(DHCreateParam sessionId);

    Boolean heartbeat(String sessionId);

    DHSendMessageResponse commandQueue(DHSendMessageParam dhSendMessageParam);
}
