package com.timeline.vpn.common.component;

import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.springframework.boot.context.event.ApplicationStartedEvent;
import org.springframework.context.ApplicationListener;
import org.springframework.stereotype.Component;
import org.springframework.util.CustomizableThreadCreator;

import javax.annotation.PreDestroy;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * @description: 线程池监控工具类
 * @author: liuguohong
 * @create: 2020/02/05 22:12
 */
@Component
@Slf4j(topic = "threadPoolMonitor")
public class ThreadPoolMonitorUtils implements ApplicationListener<ApplicationStartedEvent> {

    private ScheduledExecutorService executorService = Executors.newScheduledThreadPool(3,
            new NamedThreadFactory("ThreadPoolMonitor"));
    private static CopyOnWriteArrayList<ThreadPoolExecutor> toPrintThreadPools = new CopyOnWriteArrayList<>();

    private AtomicBoolean isRunning = new AtomicBoolean(false);

    public void print() {
        log.info("thread pool monitor started.");
        toPrintThreadPools.add(((ScheduledThreadPoolExecutor) executorService));
        Runnable printTask = () -> {
            for (ThreadPoolExecutor executorService : toPrintThreadPools) {
                printThreadPoolStatus(executorService);
            }
        };
        executorService.scheduleWithFixedDelay(printTask, 60, 60, TimeUnit.SECONDS);
    }

    /**
     * 线上有连接池获取不到的情况，不能确定连接池的情况，这里加入监控，后面可以去除
     *
     * @param tpe
     */
    private void printThreadPoolStatus(ThreadPoolExecutor tpe) {
        String threadFactoryNamePrefix = "";
        ThreadFactory threadFactory = tpe.getThreadFactory();
        if (threadFactory instanceof NamedThreadFactory) {
            threadFactoryNamePrefix = ((NamedThreadFactory) threadFactory).getNamePrefix();
        } else if (threadFactory instanceof CustomizableThreadCreator) {
            threadFactoryNamePrefix = ((CustomizableThreadCreator) threadFactory).getThreadNamePrefix();
        }
        if (StringUtils.isBlank(threadFactoryNamePrefix)) return;
        log.debug("线程池: {} {}", threadFactoryNamePrefix, tpe);
    }

    /**
     * 添加到线程池的监控中,线程必须是NamedThreadFactory
     *
     * @param executorService
     */
    public static void addToMonitor(ExecutorService executorService) {
        try {
            if (executorService instanceof ThreadPoolExecutor) {
                toPrintThreadPools.add((ThreadPoolExecutor) executorService);
            }
        } catch (Exception e) {
            log.error("addToMonitor error", e);  //监控不影响
        }
    }

    @PreDestroy
    public void destroy() {
        executorService.shutdown();
        toPrintThreadPools.clear();
        log.info("monitor destroy success");
    }

    @Override
    public void onApplicationEvent(ApplicationStartedEvent event) {
        if (isRunning.compareAndSet(false, true)) {
            print();
        }
    }
}
