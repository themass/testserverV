package com.timeline.vpn.common.service.impl.llm.dto;

import lombok.Data;

@Data
public class ChatResponse {

    private String role;

    private String content;

    private String teacherResponse;

    private boolean isRight;

    private int finished;

    private boolean finishPhase;

    private boolean finishEpoch;

    private String name;

    private String studentName;

    private String traceId;
}
