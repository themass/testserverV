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
public class YuaiResponse {
    private int code;
    private String status;
    private String digitalLiveID;
    private String sequenceID;

    public boolean isSuccess() {
        return code == 0;
    }
}
