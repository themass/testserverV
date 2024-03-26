package com.timeline.vpn.service.impl;

import com.alibaba.fastjson.JSONObject;
import com.google.common.reflect.TypeToken;
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

import java.util.*;
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
                "可以简洁明了的回答用户的问题。\n" +
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
        String value = Optional.ofNullable(history).orElse(null).stream().map(role -> {
                    return role.getRole()+role.getText();
                })
                .collect(Collectors.joining("\n"));
        return value;
    }
    public static void main(String[] args) throws Exception {
        ChatServiceImpl chatService = new ChatServiceImpl();
        Choice vo = chatService.chatWithGpt(null,"200字的小说","哈哈哈");
        System.out.println(vo);
    }
}
