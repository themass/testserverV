package com.timeline.vpn.service.impl.handle.chat;

import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.model.vo.Message;
import com.volcengine.ark.runtime.model.completion.chat.*;
import com.volcengine.ark.runtime.service.ArkService;
import com.volcengine.model.maas.api.Api;
import com.volcengine.service.maas.MaasService;
import com.volcengine.service.maas.impl.MaasServiceImpl;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;
import java.util.ArrayList;
import java.util.List;

/**
 * @author gqli
 * @version V1.0
 * @Description: 5-10; vip3 15天
 * @date 2018年7月31日 下午4:25:18
 */
@Component
public class ChatDoubaoHandler extends BaseChatHandleProxy {
    private static String  appKey = "e8995123-8a55-4529-" ;
    private static String  appKey2 =  "ae57-cd3f5fbd5eaf";
    private static String modelName = "ep-20240527113904-mrr8p";
    private static String endPoint = "https://ark.cn-beijing.volces.com/api/v3/";
    ArkService service = null;
    @PostConstruct
    private void init() {
        service = ArkService.builder().apiKey(appKey+appKey2).baseUrl(endPoint).build();
    }

    @Override
    public boolean support(Integer t) {
        return t==3;
    }

    public Choice chatWithGpt(BaseQuery baseQuery, String prompt) throws Exception {
        final List<ChatMessage> messages = new ArrayList<>();
        final ChatMessage system = ChatMessage.builder().role(ChatMessageRole.SYSTEM).content("你是一个智能AI小助手").build();
        final ChatMessage user = ChatMessage.builder().role(ChatMessageRole.USER).content(prompt).build();
        messages.add(system);
        messages.add(user);
        ChatCompletionRequest streamChatCompletionRequest = ChatCompletionRequest.builder()
                .model(modelName)
                .messages(messages)
                .build();
        ChatCompletionResult chatCompletionResult =service.createChatCompletion(streamChatCompletionRequest);
        LOGGER.info("ChatDoubaoHandler 豆包 输入："+prompt);
        LOGGER.info("ChatDoubaoHandler 豆包 chat 回复 : " + chatCompletionResult.getChoices().getFirst().getMessage().getContent());
        for (ChatCompletionChoice choices : chatCompletionResult.getChoices()) {
            Choice choice = new Choice();
            Message message = new Message();
            message.setContent(choices.getMessage().getContent().toString().replace("user","").replace("assistant","").replace("[]:",""));
            message.setRole(choices.getMessage().getRole().toString());
            choice.setMessage(message);
            return choice;

        }

        return null;
    }

}

