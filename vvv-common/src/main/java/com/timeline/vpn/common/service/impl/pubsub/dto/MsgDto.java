package com.timeline.vpn.common.service.impl.pubsub.dto;

import lombok.*;

/**
 * @Author： liguoqing
 * @Date： 2024/4/19 19:52
 * @Describe：
 */
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
@ToString
public class MsgDto {
    private String roomId;
    private MsgType msgType;
    private String message;
    private MsgSource msgSource;
}
