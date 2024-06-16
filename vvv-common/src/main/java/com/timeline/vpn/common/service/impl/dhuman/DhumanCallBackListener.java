package com.timeline.vpn.common.service.impl.dhuman;

import com.timeline.vpn.common.service.impl.dhuman.dto.DHCallbackRequest;

/**
 * @Author： liguoqing
 * @Date： 2024/4/17 14:05
 * @Describe：
 */
public interface DhumanCallBackListener {
    public void complete(DHCallbackRequest callbackRequest);
}
