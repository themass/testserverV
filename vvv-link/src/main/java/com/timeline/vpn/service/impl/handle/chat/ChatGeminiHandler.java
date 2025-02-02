package com.timeline.vpn.service.impl.handle.chat;

import com.timeline.vpn.model.chat.ChatMessages;
import com.timeline.vpn.model.chat.ChatMsg;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.ChatVo;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.util.JsonUtil;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

/**
 * @Description: 5-10; vip3 15天
 * @author gqli
 * @date 2018年7月31日 下午4:25:18
 * @version V1.0
 */
@Component
public class ChatGeminiHandler extends BaseChatHandleProxy {
    public static String url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=";
    public static String apiKey = "AIzaSyCD3x9";
    public static String apiKey2 = "jEgNQbm48K";
    public static String apiKey1 = "OOmsbokSo4SNubp4aI";
    ;
  @Override
  public boolean support(Integer t) {
        return  false;
  }
    public Choice chatWithGpt(BaseQuery baseQuery, String prompt) throws Exception {
        List<ChatMsg> chatMessageList = new ArrayList<>();
        chatMessageList.add(new ChatMsg("system","你是一个智能AI小助手"));

        ChatMessages chatMessages = new ChatMessages();
//        chatMessages.setModel("gpt-4o-mini");
        chatMessages.setTopP(0.5);
        chatMessages.setMaxTokens(3000);
        chatMessages.setTemperature(0.2);
        chatMessages.setStream(Boolean.FALSE);
        chatMessageList.add(new ChatMsg("user",prompt));
        chatMessages.setMessages(chatMessageList);
        LOGGER.info("ChatGeminiHandler Gemini 输入："+prompt);
        okhttp3.MediaType mediaType = okhttp3.MediaType.parse("application/json");
        okhttp3.RequestBody body = okhttp3.RequestBody.create(mediaType, JsonUtil.writeValueAsString(chatMessages));
        okhttp3.Request httpRequest = new okhttp3.Request.Builder()
                .url(url+apiKey+apiKey2+apiKey1)
//                .addHeader("Authorization", )
                .addHeader("stream", "false")
                .post(body)
                .build();
        okhttp3.Response response = httpClient.newCall(httpRequest).execute();
        String res = response.body().string();
        ChatVo vo = JsonUtil.readValue(res,ChatVo.class);
        LOGGER.info("ChatGeminiHandler Gemini  chat 回复 : "+vo.getChoices());
        if(vo.getChoices()!=null&&vo.getChoices().size()>0){
            Choice choice =  vo.getChoices().get(0);
            return choice;
        }
        return null;
    }
}

