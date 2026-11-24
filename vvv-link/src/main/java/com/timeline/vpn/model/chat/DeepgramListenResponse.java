package com.timeline.vpn.model.chat;

import lombok.Data;

import java.util.List;

/**
 * Deepgram listen 离线（url 模式）响应里我们用的那一小撮字段。
 *
 * <p>与流式链路共用的 SpeechRecognitionResponse 不同，那条只要 transcript；
 * 歌词要的是 alternatives[0].segments[].{start,end,transcript}（秒级浮点）。
 * JsonUtil 关掉了 FAIL_ON_UNKNOWN_PROPERTIES，多余字段自动忽略。
 */
@Data
public class DeepgramListenResponse {
    private Results results;

    @Data
    public static class Results {
        private List<Channel> channels;
    }

    @Data
    public static class Channel {
        private List<Alternative> alternatives;
    }

    @Data
    public static class Alternative {
        private String transcript;
        private List<Segment> segments;
    }

    /** 一个识别段：start/end 是相对音频起点的秒（浮点）。 */
    @Data
    public static class Segment {
        private double start;
        private double end;
        private String transcript;
    }
}
