package com.timeline.vpn.common.service.impl.tts.dto;

import lombok.Builder;
import lombok.Data;
import lombok.ToString;

/**
 * @Author： liguoqing
 * @Date： 2024/4/11 21:37
 * @Describe：
 */
@Data
@ToString
@Builder
public class OssRequest {
    private String name;
    private byte[] data;
}
