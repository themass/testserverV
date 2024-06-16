package com.timeline.vpn.common.service.impl.dhuman.dto.yuai;

import lombok.*;

/**
 * @Author： liguoqing
 * @Date： 2024/6/11 13:52
 * @Describe：
 */
@Data
@ToString
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class YuaiQueueTextRequest {
    private String digitalLiveID;
    private long sequenceID;
    private Text text;


    @Data
    @ToString
    @AllArgsConstructor
    @NoArgsConstructor
    @Builder
    public static class Text {
        private String text;
    }
}
