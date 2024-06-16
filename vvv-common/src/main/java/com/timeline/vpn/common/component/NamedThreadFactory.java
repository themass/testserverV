package com.timeline.vpn.common.component;

import com.google.common.base.Preconditions;
import org.apache.commons.lang3.StringUtils;

import java.util.concurrent.ThreadFactory;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * @description: 命名线程池
 * @author: liuguohong
 * @create: 2019/09/25 19:34
 */

public class NamedThreadFactory implements ThreadFactory {
    private static final AtomicInteger poolNumber = new AtomicInteger(1);
    private final ThreadGroup group;
    private final AtomicInteger threadNumber = new AtomicInteger(1);
    private final String namePrefix;

    private final boolean mDaemon;

    public NamedThreadFactory(String factoryName) {
        this(factoryName, false);
    }

    public NamedThreadFactory(String factoryName, boolean mDaemon) {
        Preconditions.checkArgument(StringUtils.isNotBlank(factoryName), "factoryName is null");
        SecurityManager s = System.getSecurityManager();
        this.mDaemon = mDaemon;
        group = (s != null) ? s.getThreadGroup() :
                Thread.currentThread().getThreadGroup();
        namePrefix = factoryName + "-pool-" +
                poolNumber.getAndIncrement() +
                "-thread-";
    }

    @Override
    public Thread newThread(Runnable r) {
        Thread t = new Thread(group, r,
                namePrefix + threadNumber.getAndIncrement(),
                0);
        t.setDaemon(mDaemon);
        if (t.getPriority() != Thread.NORM_PRIORITY)
            t.setPriority(Thread.NORM_PRIORITY);
        return t;
    }

    public String getNamePrefix() {
        return namePrefix;
    }
}
