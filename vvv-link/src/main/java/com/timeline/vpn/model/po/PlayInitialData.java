package com.timeline.vpn.model.po;

import kotlin.jvm.Strictfp;
import lombok.Data;
import lombok.ToString;

@Data
@ToString
public class PlayInitialData {
    private CurrentInfo current;
    @Data
    @ToString
    public static class CurrentInfo {
        private String src;
    }
}
