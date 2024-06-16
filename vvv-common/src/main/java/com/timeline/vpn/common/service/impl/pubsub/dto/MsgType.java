package com.timeline.vpn.common.service.impl.pubsub.dto;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import com.google.common.base.Preconditions;
import lombok.Getter;
import org.apache.commons.lang3.StringUtils;

import java.util.Arrays;

@Getter
public enum MsgType {
    TO_STUDENT("TO_STUDENT", "发给学生"),
    TO_TECHER("TO_TECHER", "发给老师");

    @JsonValue
    private final String toType;
    private final String desc;

    MsgType(String toType, String desc) {
        this.toType = toType;
        this.desc = desc;
    }

    @JsonCreator
    public static MsgType getMsgType(String toType) {
        Preconditions.checkArgument(StringUtils.isNotBlank(toType), "toType can not be null or empty");
        MsgType type = Arrays.stream(MsgType.values()).filter(o -> o.getToType().equals(toType)).findFirst().get();
        if (type == null) {
            throw new IllegalArgumentException("toType does no contains: " + toType);
        }
        return type;
    }

}
