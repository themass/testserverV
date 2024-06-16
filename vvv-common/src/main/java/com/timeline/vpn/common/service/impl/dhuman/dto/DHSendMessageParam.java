package com.timeline.vpn.common.service.impl.dhuman.dto;

import lombok.*;

/**
 * @Author： liguoqing
 * @Date： 2024/5/17 11:22
 * @Describe：
 */
@Data
@ToString
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class DHSendMessageParam {
    private String sessionId;
    private String context;
    private String userId;
    private String lessonId;
    private ProtocolEnum protocol;



    public  enum ProtocolEnum {
        HTTP, TEXT,  BINARY;
    }
}
