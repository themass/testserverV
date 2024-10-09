package com.timeline.vpn.service.impl.handle.chat;

import com.azure.ai.openai.OpenAIClient;
import com.azure.ai.openai.OpenAIClientBuilder;
import com.azure.ai.openai.OpenAIServiceVersion;
import com.azure.ai.openai.models.*;
import com.azure.core.credential.AzureKeyCredential;
import com.timeline.vpn.model.form.ChatContentForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.ChatVo;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.util.JsonUtil;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * @author gqli
 * @version V1.0
 * @Description: 5-10; vip3 15天
 * @date 2018年7月31日 下午4:25:18
 */
@Component
public class ChatYuaiHandler extends BaseChatHandleProxy {
    private static final String chatGptUrl = "https://aitogehter-ailesson.openai.azure.com/";
    public static String key = "8d3eb3e0779b4537";
    public static String key2 = "b143232b40b8645e";
    public static Map<String, String> header = new HashMap<>();

    static {
        header.put("Authorization", "Bearer " + key+key2);
    }

    private static OpenAIClient client = new OpenAIClientBuilder()
            .credential(new AzureKeyCredential(key+key2))
            .endpoint(chatGptUrl)
            .serviceVersion(OpenAIServiceVersion.V2024_05_01_PREVIEW)
            .buildClient();

    @Override
    public boolean support(Integer t) {
        return false;
    }

    public Choice chatWithGpt(BaseQuery baseQuery, String prompt) throws Exception {

        List<ChatRequestMessage> chatMessages = new ArrayList<>();
        chatMessages.add(new ChatRequestSystemMessage("你是一个智能AI小助手"));
        ChatCompletionsOptions chatCompletionsOptions = new ChatCompletionsOptions(chatMessages);
        chatCompletionsOptions.setModel("gpt-4o-mini");
        chatCompletionsOptions.setTopP(0.5);
        chatCompletionsOptions.setMaxTokens(2048);
        chatCompletionsOptions.setTemperature(0.2);
        chatCompletionsOptions.setStream(Boolean.FALSE);
        chatMessages.add(new ChatRequestUserMessage(prompt));
        LOGGER.info("ChatYuaiHandler 与爱 chat 输入 : " + prompt);
        ChatCompletions chatCompletions = client.getChatCompletions("gpt-4o", chatCompletionsOptions);
        ChatVo vo = JsonUtil.readValue(JsonUtil.writeValueAsString(chatCompletions), ChatVo.class);
        LOGGER.info("ChatYuaiHandler 与爱 chat 回复 : " + JsonUtil.writeValueAsString(chatCompletions));
        if (vo.getChoices() != null && vo.getChoices().size() > 0) {
            Choice choice = vo.getChoices().get(0);
            choice.getMessage().setContent(choice.getMessage().getContent().replace("user","").replace("assistant",""));
            return choice;
        }
        return null;
    }

}

