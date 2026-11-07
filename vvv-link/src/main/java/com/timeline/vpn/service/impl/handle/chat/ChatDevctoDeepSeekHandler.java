package com.timeline.vpn.service.impl.handle.chat;

import com.timeline.vpn.util.Secrets;

import com.timeline.vpn.common.annotation.MethodTimed;
import com.timeline.vpn.model.chat.ChatMessages;
import com.timeline.vpn.model.chat.ChatMsg;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.ChatVo;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.util.JsonUtil;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.function.Function;

import java.util.ArrayList;
import java.util.List;

/**
 * @Description: 5-10; vip3 15天
 * @author gqli
 * @date 2018年7月31日 下午4:25:18
 * @version V1.0
 */
@Component
@MethodTimed
public class    ChatDevctoDeepSeekHandler extends BaseChatHandleProxy {
    public static String url = "https://api.agicto.cn/v1/chat/completions";
//    public static String url = "http://openapi2.ok123find.top";
    public static String apiKey = "Bearer sk";
    public static String apiKey2 = Secrets.get("devcto_deepseek.apiKey2");
    public static String apiKey1 = Secrets.get("devcto_deepseek.apiKey1");
    ;
  @Override
  public boolean support(Integer t) {
        return  t<=6 && t>=3;
  }
    @Override
    public boolean supportsStream() {
        return true;
    }

    @Override
    protected void doStream(BaseQuery baseQuery, String prompt, String msgId, long sessionId, SseEmitter emitter, Function<String, Long> onComplete) throws Exception {
        streamOpenAiCompatible(url, apiKey + apiKey2 + apiKey1, "deepseek-v3.2", prompt,
                "你是一个智能AI小助手", 0.2, 0.5, 3000, msgId, sessionId, "ChatDevctoDeepSeekHandler", emitter, onComplete);
    }

    public Choice chatWithGpt(BaseQuery baseQuery, String prompt) throws Exception {
        List<ChatMsg> chatMessageList = new ArrayList<>();
        chatMessageList.add(new ChatMsg("system","你是一个智能AI小助手"));

        ChatMessages chatMessages = new ChatMessages();
        chatMessages.setModel("deepseek-v3.2");
        chatMessages.setTopP(0.5);
        chatMessages.setMaxTokens(3000);
        chatMessages.setTemperature(0.2);
        chatMessages.setStream(Boolean.FALSE);
        chatMessageList.add(new ChatMsg("user",prompt));
        chatMessages.setMessages(chatMessageList);
        LOGGER.info("ChatDevctoDeepSeekHandler Devcto-deepseek 输入："+prompt);
        okhttp3.MediaType mediaType = okhttp3.MediaType.parse("application/json");
        okhttp3.RequestBody body = okhttp3.RequestBody.create(mediaType, JsonUtil.writeValueAsString(chatMessages));
        okhttp3.Request httpRequest = new okhttp3.Request.Builder()
                .url(url)
                .addHeader("Authorization", apiKey+apiKey2+apiKey1)
                .addHeader("stream", "false")
                .post(body)
                .build();
        okhttp3.Response response = httpClient.newCall(httpRequest).execute();
        String res = response.body().string();
        ChatVo vo = JsonUtil.readValue(res,ChatVo.class);
        LOGGER.info("ChatDevctoDeepSeekHandler Devcto-deepseek  chat 回复 : "+vo.getChoices());
        if(vo.getChoices()!=null&&vo.getChoices().size()>0){
            Choice choice =  vo.getChoices().get(0);
            choice.setProd("ChatDevctoDeepSeekHandler");
            return choice;
        }
        return null;
    }
}

