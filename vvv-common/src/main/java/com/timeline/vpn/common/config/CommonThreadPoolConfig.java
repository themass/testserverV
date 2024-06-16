package com.timeline.vpn.common.config;

import com.timeline.vpn.common.component.NamedThreadFactory;
import com.timeline.vpn.common.component.ThreadPoolMonitorUtils;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@Configuration
public class CommonThreadPoolConfig {
    /**
     * 学生直播会话心跳 线程池
     *
     * @return
     */
    @Bean("dhumanHeartbeatExecutor")
    public ExecutorService dhumanHeartbeatExecutor() {
        ExecutorService threadPoolTaskExecutor = Executors.newScheduledThreadPool(15,
                new NamedThreadFactory("dhumanHeartbeatExecutor"));
        ThreadPoolMonitorUtils.addToMonitor(threadPoolTaskExecutor);
        return threadPoolTaskExecutor;
    }

    @Bean("ossPushExecutor")
    public ExecutorService ossPushExecutor() {
        ExecutorService threadPoolTaskExecutor = Executors.newScheduledThreadPool(15,
                new NamedThreadFactory("ossPushExecutor"));
        ThreadPoolMonitorUtils.addToMonitor(threadPoolTaskExecutor);
        return threadPoolTaskExecutor;
    }

    @Bean("subExec")
    public ExecutorService subExec() {
        ExecutorService threadPoolTaskExecutor = Executors.newScheduledThreadPool(5,
                new NamedThreadFactory("subExec"));
        ThreadPoolMonitorUtils.addToMonitor(threadPoolTaskExecutor);
        return threadPoolTaskExecutor;
    }
    @Bean("llmApply")
    public ExecutorService llmApply() {
        ExecutorService threadPoolTaskExecutor = Executors.newScheduledThreadPool(40,
                new NamedThreadFactory("llmApply"));
        ThreadPoolMonitorUtils.addToMonitor(threadPoolTaskExecutor);
        return threadPoolTaskExecutor;
    }

    @Bean("voiceExec")
    public ExecutorService voiceExec() {
        ExecutorService threadPoolTaskExecutor = Executors.newScheduledThreadPool(5,
                new NamedThreadFactory("voiceExec"));
        ThreadPoolMonitorUtils.addToMonitor(threadPoolTaskExecutor);
        return threadPoolTaskExecutor;
    }

}
