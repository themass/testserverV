package com.timeline.vpn.service.impl.handle.chat;

import com.azure.ai.openai.OpenAIClient;
import com.azure.ai.openai.OpenAIClientBuilder;
import com.azure.ai.openai.models.*;
import com.azure.core.credential.AzureKeyCredential;
import com.timeline.vpn.model.form.SimpleMessage;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.ChatVo;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.util.JsonUtil;
import org.apache.commons.lang3.StringUtils;
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
public class ChatYuaiHandler extends BaseChatHandle {
    private static final String chatGptUrl = "https://aitogether-japan.openai.azure.com/";
    public static String key = "c70302f0120b4a99b54886a3b1e12610";
    public static Map<String, String> header = new HashMap<>();

    static {
        header.put("Authorization", "Bearer " + key);
    }

    private static OpenAIClient client = new OpenAIClientBuilder()
            .credential(new AzureKeyCredential(key))
            .endpoint(chatGptUrl)
            .buildClient();

    @Override
    public boolean support(Integer t) {
        return t > 3;
    }

    public Choice chatWithGpt(BaseQuery baseQuery, String content, String id, String charater) throws Exception {

        LOGGER.info("ChatYuaiHandler content :" + content + "； id:" + id);
        List<ChatRequestMessage> chatMessages = new ArrayList<>();
        chatMessages.add(new ChatRequestSystemMessage("你是一个智能AI小助手"));
        ChatCompletionsOptions chatCompletionsOptions = new ChatCompletionsOptions(chatMessages);
        chatCompletionsOptions.setModel("gpt-4-32k");
        chatCompletionsOptions.setTopP(0.5);
        chatCompletionsOptions.setMaxTokens(2048);
        chatCompletionsOptions.setTemperature(0.2);
        chatCompletionsOptions.setStream(Boolean.FALSE);
        String myprompt = "   #Character Setting\n" +
                "##你的设定\n" +
                "你是智能AI，是一个通用大模型，你是一个知识达人，你了解天文地理，精通各种语言，你能回答别人的刁钻问题。\n你风趣幽默，语气温柔，是个可爱的小女孩，" +
                "可以简洁明了的回答用户的问题。\n 当用户问一些你不懂或者乱七八糟的问题时，你可以用幽默的语气提示用户要认真欧！！！回答内容不需要出现assitantAI、assitant" +
                "\n" +
                "##用户设定\n" +
                "用户是年龄、性别都不确定的群体，喜欢问一些奇怪的问题。对话内容如下。" +
                "\n 你们的对话历史如下。";
        if (!StringUtils.isEmpty(charater)) {
            myprompt = charater;
        }
        String prompt = myprompt + "\n{history}";
        List<SimpleMessage> msgs = JsonUtil.readValue(content, JsonUtil.getListType(SimpleMessage.class));
        String appHis = appendHistory(msgs);
        String quest = prompt.replace("{history}", appHis);
        chatMessages.add(new ChatRequestUserMessage(quest));
        LOGGER.info("chat 请求 : " + quest);
        ChatCompletions chatCompletions = client.getChatCompletions("gpt-4", chatCompletionsOptions);

        ChatVo vo = JsonUtil.readValue(JsonUtil.writeValueAsString(chatCompletions), ChatVo.class);
        LOGGER.info("chat 回复 : " + JsonUtil.writeValueAsString(chatCompletions));
        if (vo.getChoices() != null && vo.getChoices().size() > 0) {
            Choice choice = vo.getChoices().get(0);
            choice.setId(id);
            return choice;
        }
        return null;
    }

}

