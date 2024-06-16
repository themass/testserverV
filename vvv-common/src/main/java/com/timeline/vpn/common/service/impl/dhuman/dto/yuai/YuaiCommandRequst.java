package com.timeline.vpn.common.service.impl.dhuman.dto.yuai;

import lombok.*;

/**
 * @Author： liguoqing
 * @Date： 2024/6/11 11:39
 * @Describe：
 */
@Data
@ToString
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class YuaiCommandRequst {
    private String digitalLiveID;
    private String roomID;
    private String token;
}
