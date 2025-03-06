package com.timeline.vpn.test;

import com.alibaba.dashscope.audio.asr.transcription.*;
import com.google.gson.*;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.Stream;

class SenseVoiceParser {

    private static final List<String> EMOTION_LIST = Arrays.asList("NEUTRAL", "HAPPY", "ANGRY", "SAD");
    private static final List<String> EVENT_LIST = Arrays.asList("Speech", "Applause", "BGM", "Laughter");
    private static final List<String> ALL_TAGS = Arrays.asList(
            "Speech", "Applause", "BGM", "Laughter", "NEUTRAL", "HAPPY", "ANGRY", "SAD", "SPECIAL_TOKEN_1");

    /**
     * 本工具用于解析 sensevoice 识别结果
     * @param data json格式的sensevoice转写结果
     * @param keepTrans 是否保留转写文本
     * @param keepEmotions 是否保留情感标签
     * @param keepEvents 是否保留事件标签
     * @return
     */
    public static JsonObject parseSenseVoiceResult(JsonObject data, boolean keepTrans, boolean keepEmotions, boolean keepEvents) {

        List<String> tagsToCleanup = ALL_TAGS.stream()
                .flatMap(tag -> Stream.of("<|" + tag + "|> ", "<|/" + tag + "|>", "<|" + tag + "|>"))
                .collect(Collectors.toList());

        JsonArray transcripts = data.getAsJsonArray("transcripts");

        for (JsonElement transcriptElement : transcripts) {
            JsonObject transcript = transcriptElement.getAsJsonObject();
            JsonArray sentences = transcript.getAsJsonArray("sentences");

            for (JsonElement sentenceElement : sentences) {
                JsonObject sentence = sentenceElement.getAsJsonObject();
                String text = sentence.get("text").getAsString();

                if (keepEmotions) {
                    extractTags(sentence, text, EMOTION_LIST, "emotion");
                }

                if (keepEvents) {
                    extractTags(sentence, text, EVENT_LIST, "event");
                }

                if (keepTrans) {
                    String cleanText = getCleanText(text, tagsToCleanup);
                    sentence.addProperty("text", cleanText);
                } else {
                    sentence.remove("text");
                }
            }

            if (keepTrans) {
                transcript.addProperty("text", getCleanText(transcript.get("text").getAsString(), tagsToCleanup));
            } else {
                transcript.remove("text");
            }

            JsonArray filteredSentences = new JsonArray();
            for (JsonElement sentenceElement : sentences) {
                JsonObject sentence = sentenceElement.getAsJsonObject();
                if (sentence.has("text") || sentence.has("emotion") || sentence.has("event")) {
                    filteredSentences.add(sentence);
                }
            }
            transcript.add("sentences", filteredSentences);
        }
        return data;
    }

    private static void extractTags(JsonObject sentence, String text, List<String> tagList, String key) {
        String pattern = "<\\|(" + String.join("|", tagList) + ")\\|>";
        Pattern compiledPattern = Pattern.compile(pattern);
        Matcher matcher = compiledPattern.matcher(text);
        Set<String> tags = new HashSet<>();

        while (matcher.find()) {
            tags.add(matcher.group(1));
        }

        if (!tags.isEmpty()) {
            JsonArray tagArray = new JsonArray();
            tags.forEach(tagArray::add);
            sentence.add(key, tagArray);
        } else {
            sentence.remove(key);
        }
    }

    private static String getCleanText(String text, List<String> tagsToCleanup) {
        for (String tag : tagsToCleanup) {
            text = text.replace(tag, "");
        }
        return text.replaceAll("\\s{2,}", " ").trim();
    }
}

public class Main {
    public static void main(String[] args) {
        // 创建转写请求参数，需要用真实apikey替换your-dashscope-api-key
        TranscriptionParam param =
                TranscriptionParam.builder()
                        // 若没有将API Key配置到环境变量中，需将下面这行代码注释放开，并将apiKey替换为自己的API Key
                        // .apiKey("apikey")
                        .model("sensevoice-v1")
                        .fileUrls(
                                Arrays.asList(
                                        "https://dashscope.oss-cn-beijing.aliyuncs.com/samples/audio/sensevoice/rich_text_example_1.wav"))
                        .parameter("language_hints", new String[] {"en"})
                        .build();
        try {
            Transcription transcription = new Transcription();
            // 提交转写请求
            TranscriptionResult result = transcription.asyncCall(param);
            System.out.println("requestId: " + result.getRequestId());
            // 等待转写完成
            result = transcription.wait(
                    TranscriptionQueryParam.FromTranscriptionParam(param, result.getTaskId()));
            // 获取转写结果
            List<TranscriptionTaskResult> taskResultList = result.getResults();
            if (taskResultList != null && taskResultList.size() > 0) {
                for (TranscriptionTaskResult taskResult : taskResultList) {
                    String transcriptionUrl = taskResult.getTranscriptionUrl();
                    HttpURLConnection connection =
                            (HttpURLConnection) new URL(transcriptionUrl).openConnection();
                    connection.setRequestMethod("GET");
                    connection.connect();
                    BufferedReader reader =
                            new BufferedReader(new InputStreamReader(connection.getInputStream()));
                    Gson gson = new GsonBuilder().setPrettyPrinting().create();
                    JsonElement jsonResult = gson.fromJson(reader, JsonObject.class);
                    System.out.println(gson.toJson(jsonResult));
                    System.out.println(gson.toJson(SenseVoiceParser.parseSenseVoiceResult(jsonResult.getAsJsonObject(), true, true, true)));
                }
            }
        } catch (Exception e) {
            System.out.println("error: " + e);
        }
        System.exit(0);
    }
}