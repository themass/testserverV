package com.timeline.vpn.service.impl;

import com.alibaba.fastjson.JSONObject;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.ChatVo;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.service.ChatService;
import com.timeline.vpn.util.HttpCommonUtil;
import com.timeline.vpn.util.JsonUtil;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import com.azure.ai.openai.OpenAIClient;
import com.azure.ai.openai.OpenAIClientBuilder;
import com.azure.ai.openai.models.*;
import com.azure.core.credential.AzureKeyCredential;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

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
    @Override
    public Choice chatWithGpt(BaseQuery baseQuery, String content, String id) throws Exception {

        List<ChatRequestMessage> chatMessages = new ArrayList<>();
//        chatMessages.add(new ChatRequestSystemMessage("哈哈哈哈"));
        chatMessages.add(new ChatRequestUserMessage(content));
        ChatCompletionsOptions chatCompletionsOptions = new ChatCompletionsOptions(chatMessages);
        chatCompletionsOptions.setModel("photon-72b-sft-240117-exp");
        chatCompletionsOptions.setTopP(0.5);
        chatCompletionsOptions.setMaxTokens(500);
        chatCompletionsOptions.setTemperature(0.2);
        chatCompletionsOptions.setStream(Boolean.FALSE);

        ChatCompletions chatCompletions = client.getChatCompletions("gpt-4", chatCompletionsOptions);

        LOGGER.info("Model ID={} is created at {}", chatCompletions.getId(), chatCompletions.getCreatedAt());
        LOGGER.info("chatCompletions {}", chatCompletions);

        for (ChatChoice choice : chatCompletions.getChoices()) {
            ChatResponseMessage message = choice.getMessage();
            LOGGER.info("Index: {}, Chat Role: {}", choice.getIndex(), message.getRole());
            LOGGER.info("Message:{}", message.getContent());
            System.out.println(message.getContent());
        }
        System.out.println(JsonUtil.writeValueAsString(chatCompletions));
        ChatVo vo = JsonUtil.readValue(JsonUtil.writeValueAsString(chatCompletions),ChatVo.class);
//        vo.setId(id);
        if(vo.getChoices()!=null&&vo.getChoices().size()>0){
            Choice choice =  vo.getChoices().get(0);
            choice.setId(id);
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

    public static void main(String[] args) throws Exception {
        ChatServiceImpl chatService = new ChatServiceImpl();
        Choice vo = chatService.chatWithGpt(null,"200字的小说","哈哈哈");
        System.out.println(vo);
    }
}
