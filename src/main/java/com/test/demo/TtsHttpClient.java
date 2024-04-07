package com.test.demo;

import com.alibaba.fastjson.JSON;
import okhttp3.*;

import java.io.IOException;

public class TtsHttpClient {

    public static final String HOST = "openspeech.bytedance.com";
    public static final String API_URL = "https://" + HOST + "/api/v1/tts";
    public static final String appid = "5133267845";
    public static final String ACCESS_TOKEN = "6_OzctVW03tghjl3up5BysHG_smYe3RK";
    public static final String uid = "388808087185088";

    public static void main(String[] args) throws IOException {
        TtsRequest ttsRequest = new TtsRequest("字节跳动人工智能实验室我要语音合成");
        System.out.println(post(API_URL, JSON.toJSONString(ttsRequest)));
    }

    public static String post(String url, String json) throws IOException {
        OkHttpClient client = new OkHttpClient();
        RequestBody body = RequestBody.create(json, MediaType.get("application/json; charset=utf-8"));
        Request request = new Request.Builder()
                .url(url)
                .post(body)
                .header("Authorization", "Bearer; " + ACCESS_TOKEN)
                .build();
        try (Response response = client.newCall(request).execute()) {
            return response.body().string();
        }
    }

}
