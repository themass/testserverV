package com.timeline.vpn.common.service.impl.tts.dto;

import lombok.Data;
import lombok.ToString;

@Data
@ToString
public class BytedanceTtsRequest {
    private App app = new App();
    private User user = new User();
    private Audio audio = new Audio();
    private Request request = new Request();
    private String token;

    @Data
    @ToString
    public class App {
        private String appid;
        private String token; // 目前未生效，填写默认值：access_token
        private String cluster;
    }

    @Data
    @ToString
    public class Audio {
        private String voice_type;
        private String encoding;
        private float speed_ratio;
        private float volume_ratio;
        private float pitch_ratio;
        private String emotion;
        private Integer sample_rate;

    }

    @Data
    @ToString
    public class Request {
        private String reqid;
        private String text;
        private String text_type;
        private String operation;
    }

    @Data
    public class User {
        private String uid; // 目前未生效，填写一个默认值就可以
    }
}