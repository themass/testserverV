package com.timeline.vpn.common.service.impl.dhuman.dto;

import lombok.*;

/**
 * @Author： liguoqing
 * @Date： 2024/5/17 11:18
 * @Describe：
 */
@Data
@ToString
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class DHCreateParam {
    private String roomId;
    private String sessionId;
    private String userId;
    private String userData;
    private String token;
    private String lessonId;
}
