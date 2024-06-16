package com.timeline.vpn.common.service.impl.llm;


import com.azure.ai.openai.models.ChatCompletions;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;

import java.util.Map;

@FeignClient(name = "bosonFeignAi", url = "${llm.config.bosonAI.endpoint}")
public interface BosonFeignAi {

    @PostMapping("/chat/completions")
    ChatCompletions chat(@RequestHeader("Authorization") String authorization, @RequestBody Map<String, Object> body);
}
