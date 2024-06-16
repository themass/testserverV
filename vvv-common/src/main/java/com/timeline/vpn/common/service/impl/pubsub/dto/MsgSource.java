package com.timeline.vpn.common.service.impl.pubsub.dto;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import lombok.Getter;
import lombok.ToString;

import java.util.Arrays;

@Getter
@ToString
public enum MsgSource {
    CALL_BACK("CALL_BACK", "数字人回调"),
    WAIT_CHECK("WAIT_CHECK", "延迟状态检查，防止前端消息丢失");

    @JsonValue
    private final String type;
    private final String desc;

    MsgSource(String type, String desc) {
        this.type = type;
        this.desc = desc;
    }

    @JsonCreator
    public static MsgSource getMsgType(String type) {
        MsgSource source = Arrays.stream(MsgSource.values()).filter(o -> o.getType().equals(type)).findFirst().orElse(CALL_BACK);
        return source;
    }
}
