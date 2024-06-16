package com.timeline.vpn.common.service;

import com.timeline.vpn.common.service.impl.tts.dto.OssRequest;

/**
 * @Author： liguoqing
 * @Date： 2024/4/11 21:34
 * @Describe：
 */
public interface OssService {
    public void putObjToOss(OssRequest request);
}
