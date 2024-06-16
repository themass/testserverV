//package com.timeline.vpn.common.component;
//
//import io.micrometer.core.instrument.ImmutableTag;
//import io.micrometer.core.instrument.Metrics;
//import io.micrometer.core.instrument.Tag;
//import lombok.Getter;
//import org.springframework.beans.BeansException;
//import org.springframework.context.ApplicationContext;
//import org.springframework.context.ApplicationContextAware;
//import org.springframework.stereotype.Component;
//
//import java.util.Arrays;
//import java.util.List;
//import java.util.concurrent.BlockingQueue;
//import java.util.concurrent.ThreadPoolExecutor;
//
///**
// * @Author xudongchang
// * @Date 2023/11/30
// */
//@Component
//@Getter
//public class MetricsUtil implements ApplicationContextAware {
//
//    public static final double[] DEFAULT_PERCENTILE = new double[]{0.5, 0.75, 0.85, 0.9, 0.95, 0.99};
//
//    /**
//     * 注册线程池监控
//     */
//    public static void registerThreadPool(String poolName, ThreadPoolExecutor executor) {
//        List<Tag> tags = Arrays.asList(new ImmutableTag("poolName", poolName));
//        Metrics.gauge("thread_pool_thread_count", tags, executor, ThreadPoolExecutor::getPoolSize);
//        Metrics.gauge("thread_pool_queue_size", tags, executor.getQueue(), BlockingQueue::size);
//        Metrics.gauge("thread_pool_core_size", tags, executor, ThreadPoolExecutor::getCorePoolSize);
//        Metrics.gauge("thread_pool_largest_size", tags, executor, ThreadPoolExecutor::getLargestPoolSize);
//        Metrics.gauge("thread_pool_max_size", tags, executor, ThreadPoolExecutor::getMaximumPoolSize);
//        Metrics.gauge("thread_pool_active_size", tags, executor, ThreadPoolExecutor::getActiveCount);
//    }
//
//    private static MetricsUtil instance;
//
//    public static MetricsUtil getInstance() {
//        return instance;
//    }
//
//    /**
//     * websocket在离线状态
//     */
//    private Gauge websocketOnOffline;
//
//    public void setApplicationContext(ApplicationContext applicationContext) throws BeansException {
//        instance = this;
//
//        CollectorRegistry collectorRegistry = applicationContext.getBean(CollectorRegistry.class);
//        // 用户在离线
//        websocketOnOffline = Gauge.build()
//                .name("websocket_onoffline")
//                .labelNames("uid")
//                .help("websocket on/offline.").register(collectorRegistry);
//    }
//}
