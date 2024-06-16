package com.timeline.vpn.common.service.impl.llm;

import com.alibaba.fastjson.JSONObject;
import com.timeline.vpn.common.annotation.MethodTimed;
import com.timeline.vpn.common.config.LlmConfig;
import com.timeline.vpn.common.exception.LlmRuntimeException;
import com.timeline.vpn.common.service.LLMService;
import com.timeline.vpn.common.service.impl.llm.dto.ChatResponse;
import com.volcengine.helper.Const;
import com.volcengine.model.maas.api.Api;
import com.volcengine.service.maas.MaasService;
import com.volcengine.service.maas.impl.MaasServiceImpl;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;
import java.util.concurrent.atomic.AtomicReference;
import java.util.function.Function;
import java.util.stream.Stream;

/**
 * BosonAi
 *
 * @author linmingyang
 */

@Slf4j
@Component(DoubaoAI.NAME)
@MethodTimed
public class DoubaoAI implements LLMService {
    @Autowired
    private LlmConfig llmConfig;
    MaasService maasService;
    public static final String NAME = "doubaoAI";

    @PostConstruct
    private void init() {
        maasService = new MaasServiceImpl(llmConfig.getConfig().get(NAME).getHost(), llmConfig.getConfig().get(NAME).getRegion());
        maasService.setAccessKey(llmConfig.getConfig().get(NAME).getAppKey());
        maasService.setSecretKey(llmConfig.getConfig().get(NAME).getSecretKey());
    }

    private Api.ChatReq buildReq(String systemMessage, String userMessage) {
        Api.ChatReq req = Api.ChatReq.newBuilder()
                .setModel(Api.Model.newBuilder().setName(llmConfig.getConfig().get(NAME).getModelName()))
                .setParameters(Api.Parameters.newBuilder()
                        .setMaxNewTokens(128)
                        .setTemperature(llmConfig.getConfig().get(NAME).getTemperature())
                        .setTopP(llmConfig.getConfig().get(NAME).getTopP())
                )
                .addMessages(Api.Message.newBuilder().setRole(Const.MaasChatRoleOfUser).setContent(userMessage))
                .build();
        return req;
    }

    public ChatResponse chat(String systemMessage, String userMessage, Function<String, String> function) {
//        log.info("DoubaoAi");
        try {
            Api.ChatReq req = buildReq(systemMessage, userMessage);
            Api.ChatResp resp = maasService.chat(req);
            log.info("LLM_Index: {}, Chat Role: {}", resp.getChoice().getIndex(), resp.getChoice().getMessage().getRole());
            log.info("LLM_Message:{}", resp.getChoice().getMessage());
            ChatResponse chatResponse = StringUtils.isNotBlank(resp.getChoice().getMessage().getContent()) ? JSONObject.parseObject(resp.getChoice().getMessage().getContent(), ChatResponse.class) : new ChatResponse();
            chatResponse.setRole(resp.getChoice().getMessage().getRole());
            chatResponse.setContent(resp.getChoice().getMessage().getContent());
            function.apply(chatResponse.getTeacherResponse());
            return chatResponse;
        } catch (Exception e) {
            log.error("DoubaoAi error", e);
            throw new LlmRuntimeException(e);
        }
    }

    public ChatResponse chatStream(String systemMessage, String userMessage, Function<String, String> function) {
        try {
            StringBuilder sb = new StringBuilder();
            AtomicReference<String> role = new AtomicReference<>("");
            Api.ChatReq req = buildReq(systemMessage, userMessage);
            Stream<Api.ChatResp> resps = maasService.streamChat(req);
            resps.forEach(resp -> {
//                log.info("doubao content:{}", resp.getChoice().getMessage().getContent());
                function.apply(resp.getChoice().getMessage().getContent());
                sb.append(resp.getChoice().getMessage().getContent());
                role.set(resp.getChoice().getMessage().getRole());
            });
            String content = sb.toString();
            ChatResponse chatResponse = StringUtils.isNotBlank(content) ? JSONObject.parseObject(content, ChatResponse.class) : new ChatResponse();
            chatResponse.setRole(role.get());
            chatResponse.setContent(content);
//            log.info("doubao chatstream role:{};content:{}", role.get(), content);
            return chatResponse;
        } catch (Exception e) {
            log.error("DoubaoAi error", e);
            throw new LlmRuntimeException(e);
        }
    }

    @Override
    public String genContent(String systemMessage, String userMessage) {
        try {
            Api.ChatReq req = buildReq(systemMessage, userMessage);
            Api.ChatResp resp = maasService.chat(req);
            log.info("Index: {}, Chat Role: {}", resp.getChoice().getIndex(), resp.getChoice().getMessage().getRole());
            log.info("Message:{}", resp.getChoice().getMessage());
            return resp.getChoice().getMessage().getContent();
        } catch (Exception e) {
            log.error("DoubaoAi error", e);
            throw new LlmRuntimeException(e);
        }
    }

}
