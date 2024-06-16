package com.timeline.vpn.common.service.impl.llm;

import cn.hutool.core.collection.CollectionUtil;
import com.alibaba.fastjson.JSONObject;
import com.azure.ai.openai.OpenAIClient;
import com.azure.ai.openai.OpenAIClientBuilder;
import com.azure.ai.openai.models.*;
import com.azure.core.credential.AzureKeyCredential;
import com.timeline.vpn.common.annotation.MethodTimed;
import com.timeline.vpn.common.config.LlmConfig;
import com.timeline.vpn.common.service.LLMService;
import com.timeline.vpn.common.service.impl.llm.dto.ChatResponse;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;
import java.util.function.Function;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * azure
 *
 * @author linmingyang
 */
@Component(OpenAI.NAME)
@Slf4j
@MethodTimed
public class OpenAI implements LLMService {

    private OpenAIClient client;
    @Autowired
    private LlmConfig llmConfig;
    public static final String NAME = "openAI";

    @PostConstruct
    public void init() {
        client = new OpenAIClientBuilder()
                .credential(new AzureKeyCredential(llmConfig.getConfig().get(NAME).getAppKey()))
                .endpoint(llmConfig.getConfig().get(NAME).getEndpoint())
                .buildClient();
    }

    @Override
    public ChatResponse chat(String systemMessage, String userMessage, Function<String, String> function) {
        //log.info("传给ai的内容:{}", userMessage);
        List<ChatRequestMessage> chatMessages = new ArrayList<>();
        chatMessages.add(new ChatRequestSystemMessage(systemMessage));
        chatMessages.add(new ChatRequestUserMessage(userMessage));
        ChatCompletionsOptions chatCompletionsOptions = new ChatCompletionsOptions(chatMessages);
        chatCompletionsOptions.setModel(llmConfig.getConfig().get(NAME).getModelName());
        chatCompletionsOptions.setTopP((double) llmConfig.getConfig().get(NAME).getTopP());
        chatCompletionsOptions.setMaxTokens(2000);
        chatCompletionsOptions.setTemperature((double) llmConfig.getConfig().get(NAME).getTemperature());
        chatCompletionsOptions.setStream(Boolean.FALSE);

        ChatCompletions chatCompletions = client.getChatCompletions("gpt-4-32k", chatCompletionsOptions);

        log.info("LLM_Model ID={} is created at {}", chatCompletions.getId(), chatCompletions.getCreatedAt());
        log.info("chatCompletions {}", chatCompletions);

        ChatResponse chatResponse;

        for (ChatChoice choice : chatCompletions.getChoices()) {
            ChatResponseMessage message = choice.getMessage();
            log.info("LLM_Index: {}, Chat Role: {}", choice.getIndex(), message.getRole());
            log.info("LLM_Message:{}", message.getContent());

            try {
                chatResponse = StringUtils.isNotBlank(message.getContent()) ? JSONObject.parseObject(message.getContent(), ChatResponse.class) : new ChatResponse();
            } catch (Exception e) {
                log.error("chatStream error", e);
                break;
            }
            chatResponse.setRole(message.getRole().toString());
            chatResponse.setContent(message.getContent());
            function.apply(chatResponse.getTeacherResponse());
            return chatResponse;

        }
        return null;
    }

    public static String extractValidJson(String input) {
        // 正则表达式匹配JSON对象
        String jsonPattern = "\\{.*?\\}";
        Pattern pattern = Pattern.compile(jsonPattern, Pattern.DOTALL);
        Matcher matcher = pattern.matcher(input);

        if (matcher.find()) {
            // 返回匹配到的第一个JSON对象
            return matcher.group();
        }
        return null; // 如果没有找到匹配的JSON对象，返回null
    }

    @Override
    public ChatResponse chatStream(String systemMessage, String userMessage, Function<String, String> function) {
        List<ChatRequestMessage> chatMessages = new ArrayList<>();
        chatMessages.add(new ChatRequestSystemMessage(systemMessage));
        chatMessages.add(new ChatRequestUserMessage(userMessage));
        ChatCompletionsOptions chatCompletionsOptions = new ChatCompletionsOptions(chatMessages);
        chatCompletionsOptions.setModel(llmConfig.getConfig().get(NAME).getModelName());
        chatCompletionsOptions.setTopP(0.5);
        chatCompletionsOptions.setMaxTokens(2048);
        chatCompletionsOptions.setTemperature(0.2);
        chatCompletionsOptions.setStream(Boolean.TRUE);
        StringBuilder sb = new StringBuilder();
        AtomicReference<String> role = new AtomicReference<>("");
        client.getChatCompletionsStream(llmConfig.getConfig().get(NAME).getModelName(), chatCompletionsOptions)
                .forEach(chatCompletions -> {
                    if (CollectionUtil.isEmpty(chatCompletions.getChoices())) {
                        return;
                    }
                    ChatResponseMessage delta = chatCompletions.getChoices().get(0).getDelta();
                    function.apply(delta.getContent());
                    if (delta.getRole() != null) {
                        log.info("Role = " + delta.getRole());
                        role.set(delta.getRole().toString());
                    }
                    if (delta.getContent() != null) {
                        String content = delta.getContent();
                        sb.append(content);
                    }
                });
        String result = extractValidJson(sb.toString());
        ChatResponse chatResponse = null;
        try {
            chatResponse = StringUtils.isNotBlank(result) ? JSONObject.parseObject(result, ChatResponse.class) : new ChatResponse();
        } catch (Exception e) {
            log.error("error to json:{}", result);
            result.replace("# Output", "");
            chatResponse = StringUtils.isNotBlank(result) ? JSONObject.parseObject(result, ChatResponse.class) : new ChatResponse();
        }
        chatResponse.setRole(role.get());
        chatResponse.setContent(result);
//        log.info("openai chatstream role:{};content:{}", role.get(), result);
        return chatResponse;
    }

    @Override
    public String genContent(String systemMessage, String userMessage) {
        List<ChatRequestMessage> chatMessages = new ArrayList<>();
        chatMessages.add(new ChatRequestSystemMessage(systemMessage));
        chatMessages.add(new ChatRequestUserMessage(userMessage));
        ChatCompletionsOptions chatCompletionsOptions = new ChatCompletionsOptions(chatMessages);
        chatCompletionsOptions.setModel(llmConfig.getConfig().get(NAME).getModelName());
        chatCompletionsOptions.setTopP(0.5);
        chatCompletionsOptions.setMaxTokens(1000);
        chatCompletionsOptions.setTemperature(0.2);
        chatCompletionsOptions.setStream(Boolean.FALSE);

        ChatCompletions chatCompletions = client.getChatCompletions("gpt-4", chatCompletionsOptions);
//        log.info("openai chatCompletions content:{}", JacksonJsonUtil.toJsonStr(chatCompletions));
        for (ChatChoice choice : chatCompletions.getChoices()) {
            return choice.getMessage().getContent();
        }
        return null;
    }

}


