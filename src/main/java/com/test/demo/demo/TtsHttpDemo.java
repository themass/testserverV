package com.test.demo.demo;

import com.alibaba.fastjson.JSON;
import okhttp3.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.UUID;

public class TtsHttpDemo {
    private static final Logger log = LoggerFactory.getLogger(TtsHttpDemo.class);
    public static final String API_URL = "https://openspeech.bytedance.com/api/v1/tts";

    public static void main(String[] args) throws IOException {
        // set your appid and access_token
        String appid = "5133267845";
        String accessToken = "6_OzctVW03tghjl3up5BysHG_smYe3RK";
        String uid = "388808087185088";


        TtsRequest ttsRequest = TtsRequest.builder()
            .app(TtsRequest.App.builder()
                .appid(appid)
                .cluster("volcano_tts")
                .build())
            .user(TtsRequest.User.builder()
                .uid(uid)
                .build())
            .audio(TtsRequest.Audio.builder()
                .encoding("mp3")
                .voiceType("BV001_streaming")
                .build())
            .request(TtsRequest.Request.builder()
                .reqID(UUID.randomUUID().toString())
                .operation("query")
                .text("字节跳动语音合成")
                .build())
            .build();


        String reqBody = JSON.toJSONString(ttsRequest);
        log.info("request: {}", reqBody);

        OkHttpClient client = new OkHttpClient();
        RequestBody body = RequestBody.create(reqBody, MediaType.get("application/json; charset=utf-8"));
        Request request = new Request.Builder()
            .url(API_URL)
            .header("Authorization", "Bearer;" + accessToken)
            .post(body)
            .build();

        Response response = client.newCall(request).execute();
        log.info("response: {}", response.body().string());
        System.exit(0);
    }
}
