package com.timeline.vpn.model.chat;

import com.fasterxml.jackson.annotation.JsonCreator;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.Arrays;

/**
 * @Author： liguoqing
 * @Date： 2024/9/27 11:19
 * @Describe：
 */
@Getter
@AllArgsConstructor
public enum UserRole {
    user("[user]"),assistant("[assistant]");
    private String role;
    @JsonCreator
    public static UserRole getContext(String role) {
        return Arrays.stream(UserRole.values()).filter(o -> o.name().equals(role)).findFirst().get();
    }

}
