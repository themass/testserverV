package com.timeline.vpn.common.service;

import com.timeline.vpn.common.service.impl.llm.dto.ChatResponse;

import java.util.function.Function;

public interface LLMService {

    ChatResponse chat(String systemMessage, String userMessage, Function<String, String> function);

    ChatResponse chatStream(String systemMessage, String userMessage, Function<String, String> function);

    String genContent(String systemMessage, String userMessage);

}
