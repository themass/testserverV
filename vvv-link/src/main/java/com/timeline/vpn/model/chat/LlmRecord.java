package com.timeline.vpn.model.chat;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public  class LlmRecord{
    private String text;
    private long sessionId;
    private UserRole role;

}