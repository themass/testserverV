package com.timeline.vpn.common.service.impl.tts.dto;

import lombok.Data;
import lombok.ToString;

import java.util.List;

@Data
@ToString
public class TtsVolcResponse {

    private String reqid;
    private int code;
    private String operation;
    private String message;
    private int sequence;
    private String data; // 注意：这里假设你会自行处理base64编码的数据
    private Addition addition;
    private String cdnUrl;

    // getters 和 setters
    @Data
    @ToString
    public static class Addition {
        private String description;
        private String duration;
        private String frontend; // 这是一个JSON字符串，可能需要额外的处理来解析

        // getters 和 setters

        // 这里可以添加一个方法来解析 frontend 字符串为下面的 Frontend 对象
        // public Frontend parseFrontend() {...}
    }

    @Data
    @ToString
    // 假设你有一个方法来解析 frontend 字符串，那么 Frontend 类可能看起来是这样的
    public static class Frontend {
        private List<Word> words;
        private List<Phoneme> phonemes;

        // getters 和 setters
    }

    @Data
    @ToString
    public static class Word {
        private String word;
        private double startTime;
        private double endTime;

        // getters 和 setters
    }

    @Data
    @ToString
    public static class Phoneme {
        private String phone;
        private double startTime;
        private double endTime;

        // getters 和 setters
    }
}
