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

    /**
     * 声音馆歌词离线 ASR 生成线程池（契约 sound-lyrics-contract §2 Phase 2）。
     * 一次任务 = 一次 Deepgram url 模式调用（服务端拉整条音频，分钟级），刻意窄：
     * 按需触发同条目已有去重，补量 job 每轮也有限条，宽池只会把 Deepgram 并发配额打爆。
     */
    @Bean("soundAsrExecutor")
    public ExecutorService soundAsrExecutor() {
        ExecutorService threadPoolTaskExecutor = Executors.newFixedThreadPool(3,
                new NamedThreadFactory("soundAsrExecutor"));
        ThreadPoolMonitorUtils.addToMonitor(threadPoolTaskExecutor);
        return threadPoolTaskExecutor;
    }

}
