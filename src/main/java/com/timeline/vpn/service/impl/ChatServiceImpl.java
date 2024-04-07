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
    private static final String chatGptUrl = "https://aitogether-japan.openai.azure.com/";
    public static String key = "c70302f0120b4a99b54886a3b1e12610";
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
    @Override
    public Choice chatWithGpt(BaseQuery baseQuery, String content, String id) throws Exception {

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
                "用户是各类群体，喜欢问一些奇怪的问题。\n{history}" ;
               ;
        //补充历史
//        String key = baseQuery.getUser().getName()+"_chat_hist";
//        String his = cacheService.get(key);
//        LOGGER.info("redis :" +his);
//        String appHis = null;
//        List<ChatHistory> chatHis = null;
//        if(!StringUtils.isEmpty(his)){
//            chatHis = JsonUtil.readValue(his, JsonUtil.getListType(ChatHistory.class));
//            if(chatHis.size()>10){
//                chatHis = chatHis.subList(chatHis.size()-10,chatHis.size()-1);
//            }
//        }else{
//            chatHis = new ArrayList<>();
//        }
//        ChatHistory newMsg = new ChatHistory();
//        newMsg.setRole("[用户]");
//        newMsg.setContent(content);
//        chatHis.add(newMsg);
//        appHis = appendHistory(chatHis);
        //发请求
        List<SimpleMessage> msgs = JsonUtil.readValue(content,JsonUtil.getListType(SimpleMessage.class));
        String appHis = appendHistory(msgs);
        String quest = prompt.replace("{history}",appHis);
        chatMessages.add(new ChatRequestUserMessage(quest));
        LOGGER.info("chat 请求 : "+quest);
        ChatCompletions chatCompletions = client.getChatCompletions("gpt-4", chatCompletionsOptions);

        ChatVo vo = JsonUtil.readValue(JsonUtil.writeValueAsString(chatCompletions),ChatVo.class);
        LOGGER.info("chat 回复 : "+JsonUtil.writeValueAsString(chatCompletions));
//        vo.setId(id);
        if(vo.getChoices()!=null&&vo.getChoices().size()>0){
            Choice choice =  vo.getChoices().get(0);
            choice.setId(id);
            //返回值写进历史
//            ChatHistory newReMsg = new ChatHistory();
//            newReMsg.setRole("[机器人]");
//            newReMsg.setContent(choice.getMessage().getContent());
//            chatHis.add(newReMsg);
//            cacheService.put(key, JsonUtil.writeValueAsString(chatHis),USERCACH_TIMEOUT);
            return choice;
        }
        return null;
//        Map<String, String> data = new HashMap<>();
//        data.put("model", "gpt-3.5-turbo-16k");
//        data.put("stream", "false");
//        data.put("messages", content);
//        String msg = HttpCommonUtil.sendPost(chatGptUrl,data,header);
//        LOGGER.info(msg);
//        return JsonUtil.readValue(msg,ChatVo.class);
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
//    public static void main(String[] args) throws Exception {
//        String content = "{user:你好}";
//        ChatServiceImpl chatService = new ChatServiceImpl();
//        Choice vo = chatService.chatWithGpt(null,content,"哈哈哈");
//        System.out.println(vo);
//    }
    private static Map<String, Object> getBody(String prompt, String content) {
        Map<String, Object> body = Maps.newHashMap();
        body.put("model", "photon-72b-sft-240117-exp");
        body.put("temperature", 0.2);
        body.put("top_p", 0.5);
        body.put("max_tokens", 128);
        body.put("stream", true);
        Map<String, Object> regexMap = Maps.newHashMap();
        String regex = "\\{\\s*\"FinishPhase\":\\s*(true|false),\\s*\"TeacherResponse\":\\s*\"(?:[^\"\\\\]|\\\\.)*\",\\s*\"StudentName\":\\s*\"(?:[^\"\\\\]|\\\\.)*\"\\s*\\}";
        Pattern pattern = Pattern.compile(regex);
        regexMap.put("regex", pattern);
        body.put("extra_body", regexMap);

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
        String url = "https://api.boson.ai/v1/chat/completions";
        String apiKey = "Bearer bai-qhbdYmEgm4wlMGmeHpfQijwOdsqJd69lS1dHe6gwRUDCKs6E"; // 替换为你的OpenAI API密钥
        okhttp3.OkHttpClient client = new okhttp3.OkHttpClient();
        okhttp3.MediaType mediaType = okhttp3.MediaType.parse("application/json");
        okhttp3.RequestBody body = okhttp3.RequestBody.create(mediaType, new Gson().toJson(getBody("你是一个诗人。", "写一个60个字的，关于冬天的短文，白雪、很冷、梅花")));
        okhttp3.Request httpRequest = new okhttp3.Request.Builder()
                .url(url)
                .addHeader("Authorization", apiKey)
                .addHeader("stream", "true")
                .post(body)
                .build();
        okhttp3.Response response = client.newCall(httpRequest).execute();
        String line;
        while ((line = response.body().source().readUtf8Line()) != null) {
            System.out.println(line);
        }
    }
}
