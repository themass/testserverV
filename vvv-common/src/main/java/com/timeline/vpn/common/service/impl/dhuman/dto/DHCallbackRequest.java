package com.timeline.vpn.common.service.impl.dhuman.dto;

import lombok.Data;

/**
 * 直播接管排队查询返回data对象
 *
 * @author linmingyang
 */
@Data
public class DHCallbackRequest {

    private String digitalLiveID;
    private String eventType;
    private long eventTime;
    private String sequenceID;
    private int status = 0;
}
