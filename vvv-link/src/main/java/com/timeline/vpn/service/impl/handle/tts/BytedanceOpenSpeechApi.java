package com.timeline.vpn.service.impl.handle.tts;

import com.timeline.vpn.service.impl.handle.tts.dto.BytedanceTtsRequest;
import com.timeline.vpn.service.impl.handle.tts.dto.TtsVolcResponse;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;

@FeignClient(name = "bytedanceOpenSpeechApi", url = "https://openspeech.bytedance.com")
public interface BytedanceOpenSpeechApi {
    @PostMapping(value = "/api/v1/tts")
    TtsVolcResponse getTts(@RequestHeader("Authorization") String authorization, @RequestBody BytedanceTtsRequest request);
}
