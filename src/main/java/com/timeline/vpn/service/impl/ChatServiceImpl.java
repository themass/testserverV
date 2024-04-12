package com.timeline.vpn.service.impl;

import com.alibaba.fastjson.JSONObject;
import com.google.common.collect.Lists;
import com.google.common.collect.Maps;
import com.google.common.reflect.TypeToken;
import com.google.gson.Gson;
import com.timeline.vpn.model.form.SimpleMessage;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.po.ChatHistory;
import com.timeline.vpn.model.po.ConnLogPo;
import com.timeline.vpn.model.vo.ChatVo;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.service.CacheService;
import com.timeline.vpn.service.ChatService;
import com.timeline.vpn.util.HttpCommonUtil;
import com.timeline.vpn.util.JsonUtil;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import com.azure.ai.openai.OpenAIClient;
import com.azure.ai.openai.OpenAIClientBuilder;
import com.azure.ai.openai.models.*;
import com.azure.core.credential.AzureKeyCredential;

import java.io.IOException;
import java.util.*;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import static com.timeline.vpn.service.impl.CacheServiceImpl.USERCACH_TIMEOUT;

@Service
public class ChatServiceImpl implements ChatService {
//    public static String chatGptUrl = "http://book.ok123find.top/v1/chat/completions";
    //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
    private static final String chatGptUrl = "https://aitogether-japan.openai.azure.com/";
    public static String key = "c70302f0120b4a99b54886a3b1e12610";
    public static String url = "https://api.openai.com/v1/chat/completions";
    public static String apiKey = "Bearer sk";
    public static String apiKey1 = "3TiIs5LyxJVCIU2wr";
    public static String apiKey2 = "-IA5tH6GqUNfVxUJb0gyQT3BlbkFJVWa";

//    public static okhttp3.OkHttpClient httpClient = new okhttp3.OkHttpClient();
    public static  Map<String, String> header = new HashMap<>();
    static {
        header.put("Authorization","Bearer "+key);
    }
    private static OpenAIClient client = new OpenAIClientBuilder()
            .credential(new AzureKeyCredential(key))
            .endpoint(chatGptUrl)
            .buildClient();
    private static final Logger LOGGER =
            LoggerFactory.getLogger(ChatServiceImpl.class);
    @Autowired
    private CacheService cacheService;
    public Choice chatWithGpt(BaseQuery baseQuery, String content, String id) throws Exception {
        okhttp3.OkHttpClient httpClient = new okhttp3.OkHttpClient();
        List<ChatRequestMessage> chatMessages = new ArrayList<>();
        chatMessages.add(new ChatRequestSystemMessage("你是一个智能AI小助手"));
        ChatCompletionsOptions chatCompletionsOptions = new ChatCompletionsOptions(chatMessages);
        chatCompletionsOptions.setModel("gpt-3.5-turbo");
        chatCompletionsOptions.setTopP(0.5);
        chatCompletionsOptions.setMaxTokens(500);
        chatCompletionsOptions.setTemperature(0.2);
        chatCompletionsOptions.setStream(Boolean.FALSE);
        String prompt = "   #Character Setting\n" +
                "##你的设定\n" +
                "你是智能AI，是一个通用大模型，你是一个知识达人，你了解天文地理，精通各种语言，你能回答别人的刁钻问题。\n你风趣幽默，语气温柔，是个可爱的小女孩，" +
                "可以简洁明了的回答用户的问题。\n 当用户问一些你不懂或者乱七八糟的问题时，你可以用幽默的语气提示用户要认真欧！！！" +
                "\n" +
                "##用户设定\n" +
                "用户是年龄、性别都不确定的群体，喜欢问一些奇怪的问题。对话内容如下。" +
                "\n 你们的对话历史如下。\n{history}" ;
        List<SimpleMessage> msgs = JsonUtil.readValue(content,JsonUtil.getListType(SimpleMessage.class));
        String appHis = appendHistory(msgs);
        String quest = prompt.replace("{history}",appHis);
        chatMessages.add(new ChatRequestUserMessage(quest));

        okhttp3.MediaType mediaType = okhttp3.MediaType.parse("application/json");
        okhttp3.RequestBody body = okhttp3.RequestBody.create(mediaType, JsonUtil.writeValueAsString(chatCompletionsOptions));
        okhttp3.Request httpRequest = new okhttp3.Request.Builder()
                .url(url)
                .addHeader("Authorization", apiKey+apiKey2+apiKey1)
                .addHeader("stream", "false")
                .post(body)
                .build();
        okhttp3.Response response = httpClient.newCall(httpRequest).execute();

        ChatVo vo = JsonUtil.readValue(JsonUtil.writeValueAsString(response.body().string()),ChatVo.class);
        LOGGER.info("chat 回复 : "+JsonUtil.writeValueAsString(vo));
        if(vo.getChoices()!=null&&vo.getChoices().size()>0){
            Choice choice =  vo.getChoices().get(0);
            choice.setId(id);
            return choice;
        }
        return null;
    }
    public Choice chatWithGpt1(BaseQuery baseQuery, String content, String id) throws Exception {

        LOGGER.info("content :" +content+"； id:"+id);
        List<ChatRequestMessage> chatMessages = new ArrayList<>();
        chatMessages.add(new ChatRequestSystemMessage("你是一个智能AI小助手"));
        ChatCompletionsOptions chatCompletionsOptions = new ChatCompletionsOptions(chatMessages);
        chatCompletionsOptions.setModel("photon-72b-sft-240117-exp");
        chatCompletionsOptions.setTopP(0.5);
        chatCompletionsOptions.setMaxTokens(500);
        chatCompletionsOptions.setTemperature(0.2);
        chatCompletionsOptions.setStream(Boolean.FALSE);
        String prompt = "   #Character Setting\n" +
                "##你的设定\n" +
                "你是智能AI，是一个通用大模型，你是一个知识达人，你了解天文地理，精通各种语言，你能回答别人的刁钻问题。\n你风趣幽默，语气温柔，是个可爱的小女孩，" +
                "可以简洁明了的回答用户的问题。\n 当用户问一些你不懂或者乱七八糟的问题时，你可以用幽默的语气提示用户要认真欧！！！" +
                "\n" +
                "##用户设定\n" +
                "用户是年龄、性别都不确定的群体，喜欢问一些奇怪的问题。对话内容如下。" +
                "\n 你们的对话历史如下。\n{history}" ;
               ;
        List<SimpleMessage> msgs = JsonUtil.readValue(content,JsonUtil.getListType(SimpleMessage.class));
        String appHis = appendHistory(msgs);
        String quest = prompt.replace("{history}",appHis);
        chatMessages.add(new ChatRequestUserMessage(quest));
        LOGGER.info("chat 请求 : "+quest);
        ChatCompletions chatCompletions = client.getChatCompletions("gpt-4", chatCompletionsOptions);

        ChatVo vo = JsonUtil.readValue(JsonUtil.writeValueAsString(chatCompletions),ChatVo.class);
        LOGGER.info("chat 回复 : "+JsonUtil.writeValueAsString(chatCompletions));
        if(vo.getChoices()!=null&&vo.getChoices().size()>0){
            Choice choice =  vo.getChoices().get(0);
            choice.setId(id);
            return choice;
        }
        return null;
    }
    private String appendHistory(List<SimpleMessage> history) {
        if(history==null){
            return "";
        }
        String value = Optional.ofNullable(history).orElse(null).stream().map(role -> {
                    return role.getRole()+role.getText();
                })
                .collect(Collectors.joining("\n"));
        return value;
    }
    private static Map<String, Object> getBody(String prompt, String content) {
        Map<String, Object> body = Maps.newHashMap();
        body.put("model", "gpt-3.5-turbo");
        body.put("temperature", 0.2);
        body.put("top_p", 0.5);
        body.put("max_tokens", 128);
        body.put("stream", false);
        List<Map<String, String>> messages = Lists.newArrayList();
        Map<String, String> sysMessage = Maps.newHashMap();
        sysMessage.put("role", "system");
        sysMessage.put("content", prompt);
        messages.add(sysMessage);
        Map<String, String> userMessage = Maps.newHashMap();
        userMessage.put("role", "user");
        userMessage.put("content", content);
        messages.add(userMessage);
        body.put("messages", messages);
        return body;
    }
    public static void main(String[] args) throws IOException {
        okhttp3.OkHttpClient httpClient = new okhttp3.OkHttpClient();
        okhttp3.MediaType mediaType = okhttp3.MediaType.parse("application/json");
        okhttp3.RequestBody body = okhttp3.RequestBody.create(mediaType, new Gson().toJson(getBody("你是一个诗人。", "写一个60个字的，关于冬天的短文，白雪、很冷、梅花")));
        okhttp3.Request httpRequest = new okhttp3.Request.Builder()
                .url(url)
                .addHeader("Authorization", apiKey)
                .addHeader("stream", "false")
                .post(body)
                .build();
        okhttp3.Response response = httpClient.newCall(httpRequest).execute();
        System.out.println(response.body().string());

        List<ChatRequestMessage> chatMessages = new ArrayList<>();
        chatMessages.add(new ChatRequestSystemMessage("你是一个智能AI小助手"));
        ChatCompletionsOptions chatCompletionsOptions = new ChatCompletionsOptions(chatMessages);
        chatCompletionsOptions.setModel("gpt-3.5-turbo");
        chatCompletionsOptions.setTopP(0.5);
        chatCompletionsOptions.setMaxTokens(500);
        chatCompletionsOptions.setTemperature(0.2);
        chatCompletionsOptions.setStream(Boolean.FALSE);
        String prompt = "   #Character Setting\n" +
                "##你的设定\n" +
                "你是智能AI，是一个通用大模型，你是一个知识达人，你了解天文地理，精通各种语言，你能回答别人的刁钻问题。\n你风趣幽默，语气温柔，是个可爱的小女孩，" +
                "可以简洁明了的回答用户的问题。\n 当用户问一些你不懂或者乱七八糟的问题时，你可以用幽默的语气提示用户要认真欧！！！" +
                "\n" +
                "##用户设定\n" +
                "用户是年龄、性别都不确定的群体，喜欢问一些奇怪的问题。对话内容如下。" +
                "\n 你们的对话历史如下。\n{history}" ;
        System.out.println(JsonUtil.writeValueAsString(chatCompletionsOptions));
//        List<SimpleMessage> msgs = JsonUtil.readValue(content,JsonUtil.getListType(SimpleMessage.class));
//        String appHis = appendHistory(msgs);
//        String quest = prompt.replace("{history}",appHis);
//        chatMessages.add(new ChatRequestUserMessage(quest));
    }
}
