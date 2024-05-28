package com.timeline.vpn.service.impl.handle.chat;

import com.timeline.vpn.model.chat.ChatMessages;
import com.timeline.vpn.model.chat.ChatMsg;
import com.timeline.vpn.model.form.SimpleMessage;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.po.UserPo;
import com.timeline.vpn.model.vo.ChatVo;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.util.JsonUtil;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

/**
 * @Description: 5-10; vip3 15天
 * @author gqli
 * @date 2018年7月31日 下午4:25:18
 * @version V1.0
 */
@Component
public class ChatMyGpt4Handler extends BaseChatHandle {
    public static String url = "https://api.openai.com/v1/chat/completions";
    public static String apiKey = "Bearer sk";
    public static String apiKey1 = "3TiIs5LyxJVCIU2wr";
    public static String apiKey2 = "-IA5tH6GqUNfVxUJb0gyQT3BlbkFJVWa";
  @Override
  public boolean support(Integer t) {
    return t<3;
  }
    public Choice chatWithGpt(BaseQuery baseQuery, String content, String id, String charater) throws Exception {
        LOGGER.info("ChatMyGpt4Handler content :" + content + "； id:" + id);

        okhttp3.OkHttpClient httpClient = new okhttp3.OkHttpClient();
        List<ChatMsg> chatMessageList = new ArrayList<>();
        chatMessageList.add(new ChatMsg("system","你是一个智能AI小助手"));

        ChatMessages chatMessages = new ChatMessages();
        chatMessages.setModel("gpt-3.5-turbo");
        chatMessages.setTopP(0.5);
        chatMessages.setMaxTokens(1800);
        chatMessages.setTemperature(0.2);
        chatMessages.setStream(Boolean.FALSE);

        chatMessageList.add(new ChatMsg("user",getPromt(content, charater)));
        chatMessages.setMessages(chatMessageList);
        LOGGER.info("chatWithGpt 我的gpt 输入："+JsonUtil.writeValueAsString(chatMessages));
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
        LOGGER.info("chatWithGpt 我的gpt  chat 回复 : "+res);
        if(vo.getChoices()!=null&&vo.getChoices().size()>0){
            Choice choice =  vo.getChoices().get(0);
            choice.setId(id);
            return choice;
        }
        return null;
    }

}

