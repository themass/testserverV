package com.timeline.vpn.common.service.impl.dhuman.dto.yuai;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.ToString;

import java.util.Map;

/**
 * @Author： liguoqing
 * @Date： 2024/6/11 11:39
 * @Describe：
 */
@Data
@ToString
@AllArgsConstructor
@NoArgsConstructor
public class YuaiStatResponse extends YuaiResponse {
    private Map<String, Object> result;
}
