package com.timeline.vpn.common.extension;

import lombok.NonNull;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.collections4.CollectionUtils;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.BeansException;
import org.springframework.context.ApplicationContext;
import org.springframework.context.ApplicationContextAware;
import org.springframework.core.annotation.AnnotationUtils;
import org.springframework.util.Assert;

import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

/**
 * @Description 加载、获取扩展点的工厂
 * @Author xudongchang
 * @Date 2023/9/23
 */
@Slf4j
public class ExtensionFactory implements ApplicationContextAware {
    private volatile static Map<String, Map<String, Object>> extensionsCache = new HashMap<>();

    /**
     * 获取Extensible下Extension
     *
     * @param path extensible path
     * @param name
     */
    public static <T> T getExtension(String path, String name) {
        if (StringUtils.isBlank(path)) {
            path = Extensible.DEFAULT;
        }
        if (StringUtils.isBlank(name)) {
            name = Extension.DEFAULT;
        }
        Map<String, Object> extensions = extensionsCache.get(path);
        Assert.notNull(extensions, "@Extensible path not exists " + path);
        Object extension = extensions.get(name);
        if (Objects.isNull(extension)) {
            extension = extensions.get(Extension.DEFAULT);
        }
        Assert.notNull(extension, "@Extension code not exists " + name);
        return (T) extension;
    }


    /**
     * 获取Extensible下Extension
     *
     * @param extensible extensible class
     * @param name       name
     */
    public static <T> T getExtension(@NonNull Class<T> extensible, String name) {
        Extensible annotation = AnnotationUtils.findAnnotation(extensible, Extensible.class);
        Assert.notNull(annotation, "@Extensible must not be null");
        return getExtension(annotation.path(), name);
    }

    /**
     * 获取Extensible下所有Extension
     *
     * @param path extensible path
     */
    public static <T> Collection<T> getExtensions(String path) {
        if (StringUtils.isBlank(path)) {
            path = Extensible.DEFAULT;
        }
        Map<String, Object> extensions = extensionsCache.get(path);
        Assert.notNull(extensions, "@Extensible path not exists " + path);
        return CollectionUtils.collect(extensions.values(), e -> (T) e);
    }

    /**
     * 获取Extensible下所有Extension
     *
     * @param extensible extensible class
     */
    public static <T> Collection<T> getExtensions(@NonNull Class<T> extensible) {
        Extensible annotation = AnnotationUtils.findAnnotation(extensible, Extensible.class);
        Assert.notNull(annotation, "@Extensible must not be null");
        return getExtensions(annotation.path());
    }

    private static void load(ApplicationContext applicationContext) {
        log.info("starting load extensions...");
        Map<String, Object> extensions = applicationContext.getBeansWithAnnotation(Extension.class);
        Map<String, Map<String, Object>> news = new HashMap<>();
        Map<String, Map<String, Object>> logs = new HashMap<>();
        extensions.values().forEach(obj -> {
            Extensible extensible = AnnotationUtils.findAnnotation(obj.getClass(), Extensible.class);
            if (Objects.nonNull(extensible)) {
                String path = extensible.path();
                Assert.notNull(path, "@Extensible path must not be null " + obj.getClass().getName());
                Map<String, Object> pathIn = news.computeIfAbsent(path, k -> new HashMap<>());
                Map<String, Object> pathInLog = logs.computeIfAbsent(path, k -> new HashMap<>());

                Extension extension = AnnotationUtils.findAnnotation(obj.getClass(), Extension.class);
                String name = extension.name();
                Assert.notNull(name, "@Extension name must not be null " + obj.getClass().getName());
                pathIn.put(name, obj);
                pathInLog.put(name, obj.getClass().getName());
            }
        });
        extensionsCache = news;
        log.info("success load extensions " + logs);
    }


    @Override
    public void setApplicationContext(ApplicationContext applicationContext) throws BeansException {
        load(applicationContext);
    }
}
