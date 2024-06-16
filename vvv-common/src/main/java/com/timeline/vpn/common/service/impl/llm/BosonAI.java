package com.timeline.vpn.common.service.impl.llm;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import com.azure.ai.openai.models.ChatChoice;
import com.azure.ai.openai.models.ChatCompletions;
import com.azure.ai.openai.models.ChatResponseMessage;
import com.google.common.collect.Lists;
import com.google.common.collect.Maps;
import com.timeline.vpn.common.annotation.MethodTimed;
import com.timeline.vpn.common.config.LlmConfig;
import com.timeline.vpn.common.exception.LlmRuntimeException;
import com.timeline.vpn.common.service.LLMService;
import com.timeline.vpn.common.service.impl.llm.dto.ChatResponse;
import com.timeline.vpn.common.utils.HttpCommonUtil;
import com.timeline.vpn.common.utils.JacksonJsonUtil;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.collections4.CollectionUtils;
import org.apache.commons.io.Charsets;
import org.apache.commons.lang3.StringUtils;
import org.apache.hc.client5.http.impl.classic.CloseableHttpResponse;
import org.apache.hc.core5.http.ContentType;
import org.apache.hc.core5.http.io.entity.StringEntity;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;
import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.function.Function;
import java.util.regex.Pattern;

/**
 * BosonAi
 *
 * @author linmingyang
 */
@Component(BosonAI.NAME)
@Slf4j
@MethodTimed
public class BosonAI implements LLMService {
    @Resource
    private BosonFeignAi bosonFeignAi;

    @Resource
    private LlmConfig llmConfig;

    public static final String NAME = "bosonAI";

    private static final String URL = "https://api.boson.ai/v1/chat/completions";

    public ChatResponse chat(String prompt, String content, Function<String, String> function) {
//        log.info("Boson.openai请求开始");
        String authorizationHeader = "Bearer " + llmConfig.getConfig().get(NAME).getAppKey();
        float llmTemperature = llmConfig.getConfig().get(NAME).getTemperature();
        float llmTopP = llmConfig.getConfig().get(NAME).getTopP();
        String modelName = llmConfig.getConfig().get(NAME).getModelName();
        ChatResponse chatResponse;
        int attempt = 0;
        int maxAttempts = 3;
        while (attempt < maxAttempts) {
            attempt++;
            ChatCompletions chatCompletions = bosonFeignAi.chat(authorizationHeader, getBody(prompt, content, false, llmTemperature, llmTopP, modelName));

            for (ChatChoice choice : chatCompletions.getChoices()) {
                ChatResponseMessage message = choice.getMessage();
                log.info("LLM_Index: {}, Chat Role: {}", choice.getIndex(), message.getRole());
                log.info("LLM_Message:{}", message.getContent());

                try {
                    chatResponse = StringUtils.isNotBlank(message.getContent()) ? JSONObject.parseObject(message.getContent(), ChatResponse.class) : new ChatResponse();
                } catch (Exception e) {
                    break;
                }

                chatResponse.setRole(message.getRole().toString());
                chatResponse.setContent(message.getContent());
                function.apply(chatResponse.getTeacherResponse());
                log.error("Boson.openai attempt time: {}", attempt);
                return chatResponse;
            }
        }
        log.error("Boson.openai attempt more than maxAttempts: {}", attempt);
        return null;
    }

    public ChatResponse chatStream(String prompt, String content, Function<String, String> function) {
//        log.info("Boson.openai 流式请求开始");
        String authorizationHeader = "Bearer " + llmConfig.getConfig().get(NAME).getAppKey();
        float llmTemperature = llmConfig.getConfig().get(NAME).getTemperature();
        float llmTopP = llmConfig.getConfig().get(NAME).getTopP();
        String modelName = llmConfig.getConfig().get(NAME).getModelName();
        Map<String, Object> body = getBody(prompt, content, true, llmTemperature, llmTopP, modelName);
        String str = getHttpStream(URL, authorizationHeader, JacksonJsonUtil.toJsonStr(body), function);
        ChatResponse chatResponse = JSON.parseObject(str, ChatResponse.class);
        return chatResponse;
    }

    @Override
    public String genContent(String systemMessage, String userMessage) {
//        log.info("Boson.openai请求开始");
        String authorizationHeader = "Bearer " + llmConfig.getConfig().get(NAME).getAppKey();
        float llmTemperature = llmConfig.getConfig().get(NAME).getTemperature();
        float llmTopP = llmConfig.getConfig().get(NAME).getTopP();
        String modelName = llmConfig.getConfig().get(NAME).getModelName();
        ChatCompletions chatCompletions = bosonFeignAi.chat(authorizationHeader, getBody(systemMessage, userMessage, false, llmTemperature, llmTopP, modelName));
        for (ChatChoice choice : chatCompletions.getChoices()) {
            return choice.getMessage().getContent();
        }
        return null;
    }

    private String getHttpStream(String url, String authorizationHeader, String dataJson, Function<String, String> function) {
//        log.info("getHttpStream.dataJson:{}", dataJson);
        StringBuilder str = new StringBuilder();
        try {
            Map<String, String> header = new HashMap<>();
            header.put("Content-Type", ContentType.APPLICATION_JSON.getMimeType());
            header.put("Authorization", authorizationHeader);
            StringEntity entity = new StringEntity(dataJson, Charsets.UTF_8);
            CloseableHttpResponse response = HttpCommonUtil.sendPostWithEntity(url, entity, header);
            InputStream inputStream = response.getEntity().getContent();
            // 使用BufferedReader逐行读取响应内容
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream, Charsets.UTF_8))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    String jsonStr = line.replace("data: ", "").replace("[DONE]", "").trim();
                    ChatCompletions chatCompletions = JacksonJsonUtil.readValue(jsonStr, ChatCompletions.class);
                    if (Objects.isNull(chatCompletions) || CollectionUtils.isEmpty(chatCompletions.getChoices())
                            || Objects.isNull(Objects.isNull(chatCompletions.getChoices().get(0).getDelta())
                            || "null".equals(chatCompletions.getChoices().get(0).getDelta().getContent()))
                            || StringUtils.isBlank(chatCompletions.getChoices().get(0).getDelta().getContent())) {
                        log.error("chatCompletions error:{}", chatCompletions);
                        continue;
                    }
                    str.append(chatCompletions.getChoices().get(0).getDelta().getContent());
                    String context = chatCompletions.getChoices().get(0).getDelta().getContent();
                    function.apply(context);
                    // 初始化起始索引
                }
            }
        } catch (Exception e) {
            log.error("", e);
            throw new LlmRuntimeException(e);
        }
        return str.toString();
    }

    private Map<String, Object> getBody(String prompt, String content, boolean stream, float llmTemperature, float llmTopP, String modelName) {
        Map<String, Object> body = Maps.newHashMap();
        body.put("model", modelName);
        body.put("temperature", llmTemperature);
        body.put("top_p", llmTopP);
        body.put("max_tokens", 2048);
        body.put("stream", stream);
        Map<String, Object> regexMap = Maps.newHashMap();
        String regex = "\\{\\s*\"teacherResponse\":\\s*\"(?:[^\"\\\\]|\\\\.)*\",\\s*\"finishPhase\":\\s*(true|false),\\s*\"finishEpoch\":\\s*(true|false),\\s*\"studentName\":\\s*\"(?:[^\"\\\\]|\\\\.)*\"\\s*\\}";
        Pattern pattern = Pattern.compile(regex);
        regexMap.put("regex", pattern);
        body.put("extra_body", regexMap);

        List<Map<String, String>> messages = Lists.newArrayList();
        Map<String, String> sysMessage = Maps.newHashMap();
        sysMessage.put("role", "system");
        sysMessage.put("content", prompt);
        messages.add(sysMessage);
        Map<String, String> userMessage = Maps.newHashMap();
        userMessage.put("role", "user");
        userMessage.put("content", content);
        messages.add(userMessage);
        body.put("messages", messages);

        return body;
    }

}
