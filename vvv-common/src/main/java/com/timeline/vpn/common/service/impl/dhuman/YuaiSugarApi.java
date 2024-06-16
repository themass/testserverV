package com.timeline.vpn.common.service.impl.dhuman;

import com.timeline.vpn.common.service.impl.dhuman.dto.yuai.*;
import org.springframework.cloud.context.config.annotation.RefreshScope;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.*;

@FeignClient(name = "yuaiSugarApi", url = "${dhuman.config.${dhuman.active}.base-url}")
@RefreshScope
public interface YuaiSugarApi {


    @PostMapping(value = "/ai/digitalhuman/createlive")
    YuaiResponse createLiveRoom(@RequestHeader("Source-Sn") String source, @RequestBody YuaiCreateRequst yuaiCreateRequst);

    @PostMapping(value = "/ai/digitalhuman/startlive")
    YuaiResponse startLive(@RequestHeader("Source-Sn") String source, @RequestBody YuaiCommandRequst yuaiCommandRequst);

    @GetMapping(value = "/ai/digitalhuman/querydigital")
    YuaiStatResponse queryDigitalStat(@RequestHeader("Source-Sn") String source, @ModelAttribute YuaiCommandRequst yuaiCommandRequst);

    @PostMapping(value = "/ai/digitalhuman/stoplive")
    YuaiResponse stopLive(@RequestHeader("Source-Sn") String source, @RequestBody YuaiCommandRequst yuaiCommandRequst);

    @PostMapping(value = "/ai/digitalhuman/pushaudio")
    YuaiResponse commandQueueAudio(@RequestHeader("Source-Sn") String source, @RequestBody YuaiQueueAudioRequest yuaiQueueAudioRequest);

    @PostMapping(value = "/ai/digitalhuman/pushtext")
    YuaiResponse commandQueueText(@RequestHeader("Source-Sn") String source, @RequestBody YuaiQueueTextRequest yuaiQueueTextRequest);
}
