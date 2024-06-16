package com.timeline.vpn.common.service.impl.dhuman.dto;

import lombok.*;

/**
 * 直播接管排队查询返回data对象
 *
 * @author linmingyang
 */
@Data
@ToString
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class DHSendMessageResponse {
    private String commandTraceId;
}
