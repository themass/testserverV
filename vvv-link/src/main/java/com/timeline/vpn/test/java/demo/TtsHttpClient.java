package com.timeline.vpn.test.java.demo;

import com.alibaba.fastjson.JSON;
import com.timeline.vpn.common.utils.Base64Util;
import com.timeline.vpn.util.JsonUtil;
import okhttp3.*;

import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;

public class TtsHttpClient {

    public static final String HOST = "openspeech.bytedance.com";
    public static final String API_URL = "https://" + HOST + "/api/v1/tts";
    public static final String ACCESS_TOKEN = "YJYBl-jGgkv-AZfQrwObHWfbwa5w3aAX";

    public static void main(String[] args) throws IOException {
        TtsRequest ttsRequest = new TtsRequest("hello, what is your name");
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
            String filePath = "/Users/liguoqing/Downloads/test/example.mp3";
            TtsVolcResponse response1 = JsonUtil.readValue(response.body().string(),TtsVolcResponse.class);
            try (FileOutputStream fos = new FileOutputStream(filePath)) {
                fos.write(Base64Util.decodeBase64(response1.getData())); // 写入数据
                System.out.println("Data written to file successfully.");
            } catch (IOException e) {
                e.printStackTrace(); // 打印异常信息
            }
            return response1.getMessage();
        }
    }

}
