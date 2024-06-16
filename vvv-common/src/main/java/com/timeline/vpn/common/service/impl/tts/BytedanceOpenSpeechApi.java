package com.timeline.vpn.common.service.impl.tts;

import com.timeline.vpn.common.service.impl.tts.dto.BytedanceTtsRequest;
import com.timeline.vpn.common.service.impl.tts.dto.TtsVolcResponse;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;

@FeignClient(name = "bytedanceOpenSpeechApi", url = "${tts.supplier.bytedanceTtsService.config.default.url}")
public interface BytedanceOpenSpeechApi {
    @PostMapping(value = "/api/v1/tts")
    TtsVolcResponse getTts(@RequestHeader("Authorization") String authorization, @RequestBody BytedanceTtsRequest request);
}
