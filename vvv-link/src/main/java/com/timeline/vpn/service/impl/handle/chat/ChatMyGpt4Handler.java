package com.timeline.vpn.service.impl.handle.chat;

import com.timeline.vpn.model.chat.ChatMessages;
import com.timeline.vpn.model.chat.ChatMsg;
import com.timeline.vpn.model.form.ChatContentForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.ChatVo;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.util.JsonUtil;
import okhttp3.OkHttpClient;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.ArrayList;
import java.util.List;

/**
 * @Description: 5-10; vip3 15天
 * @author gqli
 * @date 2018年7月31日 下午4:25:18
 * @version V1.0
 */
@Component
public class ChatMyGpt4Handler extends BaseChatHandleProxy {
    public static String url = "https://api.openai.com/v1/chat/completions";
//    public static String url = "http://openapi2.ok123find.top";
    public static String apiKey = "Bearer sk";
    public static String apiKey1 = "3TiIs5LyxJVCIU2wr";
    public static String apiKey2 = "-IA5tH6GqUNfVxUJb0gyQT3BlbkFJVWa";
    ;
  @Override
  public boolean support(Integer t) {
        return  t >= 6 && t < 8 ;
  }
    public Choice chatWithGpt(BaseQuery baseQuery, String prompt) throws Exception {
        List<ChatMsg> chatMessageList = new ArrayList<>();
        chatMessageList.add(new ChatMsg("system","你是一个智能AI小助手"));

        ChatMessages chatMessages = new ChatMessages();
        chatMessages.setModel("gpt-4o-mini");
        chatMessages.setTopP(0.5);
        chatMessages.setMaxTokens(1800);
        chatMessages.setTemperature(0.2);
        chatMessages.setStream(Boolean.FALSE);
        chatMessageList.add(new ChatMsg("user",prompt));
        chatMessages.setMessages(chatMessageList);
        LOGGER.info("ChatMyGpt4Handler 我的gpt 输入："+prompt);
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
        LOGGER.info("ChatMyGpt4Handler 我的gpt  chat 回复 : "+vo.getChoices());
        if(vo.getChoices()!=null&&vo.getChoices().size()>0){
            Choice choice =  vo.getChoices().get(0);
            return choice;
        }
        return null;
    }

    @Override
    public boolean isDefault() {
        return true;
    }
}

