package com.timeline.vpn.common.service.impl.dhuman.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class SessionResponse {
    private String sessionId;
    private int status;

}
