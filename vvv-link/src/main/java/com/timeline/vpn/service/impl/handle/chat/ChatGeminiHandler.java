package com.timeline.vpn.service.impl.handle.chat;

import com.timeline.vpn.common.annotation.MethodTimed;
import com.timeline.vpn.model.chat.ChatMessages;
import com.timeline.vpn.model.chat.ChatMsg;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.ChatVo;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.model.vo.Message;
import com.timeline.vpn.util.JsonUtil;
import lombok.Data;
import lombok.ToString;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * @Description: 5-10; vip3 15天
 * @author gqli
 * @date 2018年7月31日 下午4:25:18
 * @version V1.0
 */
@Component
@MethodTimed
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
        GeminiContentPartsText partsText = new GeminiContentPartsText();
        partsText.setText(prompt);
        GeminiContentParts contentParts = new GeminiContentParts();
        contentParts.setParts(Arrays.asList(partsText));
        GeminiContent chatMessages = new GeminiContent();
        chatMessages.setContents(Arrays.asList(contentParts));
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
        GeminiContentResp vo = JsonUtil.readValue(res,GeminiContentResp.class);
//        LOGGER.info("ChatGeminiHandler Gemini  chat 回复 : "+res);
        if(vo.getCandidates()!=null&&vo.getCandidates().size()>0 && vo.getCandidates().getFirst().getContent()!=null){
            GeminiContentPartsText text = vo.getCandidates().getFirst().getContent().getParts().getFirst();
            Choice choice =  new Choice();
            Message message = new Message();
            message.setContent(text.getText());
            choice.setMessage(message);
            LOGGER.info("ChatGeminiHandler Gemini  chat 回复 : "+text.getText());
            choice.setProd("ChatGeminiHandler");
            return choice;
        }
        return null;
    }
    public static class GeminiContent{
      private List<GeminiContentParts> contents;
      private GeminiContentParts content;

    public List<GeminiContentParts> getContents() {
        return contents;
    }

    public void setContents(List<GeminiContentParts> contents) {
        this.contents = contents;
    }

    public GeminiContentParts getContent() {
        return content;
    }

    public void setContent(GeminiContentParts content) {
        this.content = content;
    }
    }
    public static class GeminiContentParts{
        private List<GeminiContentPartsText> parts;

        public List<GeminiContentPartsText> getParts() {
            return parts;
        }

        public void setParts(List<GeminiContentPartsText> parts) {
            this.parts = parts;
        }
    }
    public static class GeminiContentPartsText{
        private String text;

        public String getText() {
            return text;
        }

        public void setText(String text) {
            this.text = text;
        }
    }
    public static class GeminiContentResp{
        private List<GeminiContent> candidates;

        public List<GeminiContent> getCandidates() {
            return candidates;
        }

        public void setCandidates(List<GeminiContent> candidates) {
            this.candidates = candidates;
        }
    }

    public static void main(String[] args) {
        String json = "{  \"candidates\": [{\n" +
                "            \"content\": {\n" +
                "                \"parts\": [\n" +
                "                    {\n" +
                "                        \"text\": \"I don't have a name.\\n\"\n" +
                "                    }\n" +
                "                ],\n" +
                "                \"role\": \"model\"\n" +
                "            },\n" +
                "            \"finishReason\": \"STOP\",\n" +
                "            \"avgLogprobs\": -0.0839086373647054\n" +
                "        }]}";
        GeminiContentResp vo = JsonUtil.readValue(json,GeminiContentResp.class);
        System.out.println(vo.getCandidates());

    }
}

