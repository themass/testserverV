package com.timeline.vpn.service.impl.handle.tts;

import com.timeline.vpn.service.impl.handle.tts.dto.OssRequest;

/**
 * @Author： liguoqing
 * @Date： 2024/4/11 21:34
 * @Describe：
 */
public interface OssService {
    public void putObjToOss(OssRequest request);
}
