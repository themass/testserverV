package com.timeline.vpn.common.service.impl.dhuman;

import com.timeline.vpn.common.service.impl.dhuman.dto.DHCallbackRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cloud.context.config.annotation.RefreshScope;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

/**
 * @Author： liguoqing
 * @Date： 2024/4/17 14:02
 * @Describe：
 */
@Slf4j
@Component
@RefreshScope
public class DhumanCommandbCallackService {
    private ScheduledExecutorService mockCallbackExecutor = Executors.newScheduledThreadPool(4);
    @Autowired(required = false)
    private List<DhumanCallBackListener> softSugarCallBackListeners;

    public void trySubmitMockCallback(String sessionId, String traceId) {
        mockCallbackExecutor.schedule(() -> mockCallback(sessionId, traceId), 400, TimeUnit.MILLISECONDS);
    }

    public void trySubmitMockStartLive(String sessionId) {
        mockCallbackExecutor.schedule(() -> mockStartLive(sessionId), 3000, TimeUnit.MILLISECONDS);
    }

    public void mockStartLive(String sessionId) {
        log.debug("mockStartLive success,sessionId:{}", sessionId);
        DHCallbackRequest dhCallbackRequest = new DHCallbackRequest();
        dhCallbackRequest.setDigitalLiveID(sessionId);
        dhCallbackRequest.setSequenceID("");
        dhCallbackRequest.setEventType("live_start");
        dhCallbackRequest.setStatus(0);
        for (DhumanCallBackListener listener : softSugarCallBackListeners) {
            listener.complete(dhCallbackRequest);
        }
    }

    public void mockCallback(String sessionId, String traceId) {
        DHCallbackRequest dhCallbackRequest = new DHCallbackRequest();
        dhCallbackRequest.setDigitalLiveID(sessionId);
        dhCallbackRequest.setSequenceID(traceId);
        dhCallbackRequest.setEventType("speech_end");
        dhCallbackRequest.setStatus(0);
        for (DhumanCallBackListener listener : softSugarCallBackListeners) {
            listener.complete(dhCallbackRequest);
        }
    }
}
