package com.timeline.vpn.util;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.util.Properties;

/**
 * 从外部 properties 文件读取密钥。
 *
 * 文件路径由 -Dsecrets.file 指定，默认是工作目录下的 secrets.properties。
 * 文件不在 jar 里，所以改密钥不需要重新打包。值为空或文件不存在时返回空串，
 * 调用方会在真正发请求时失败，而不是在启动时失败。
 *
 * 不用 Spring 注入：很多密钥是 static 字段的初始值，在类加载时就要拿到。
 */
public final class Secrets {

    private static final Logger LOGGER = LoggerFactory.getLogger(Secrets.class);
    private static final Properties PROPS = load();

    private Secrets() {
    }

    public static String get(String key) {
        String value = PROPS.getProperty(key);
        if (value == null || value.isEmpty()) {
            LOGGER.warn("secret '{}' is not set", key);
            return "";
        }
        return value;
    }

    private static Properties load() {
        String path = System.getProperty("secrets.file", "secrets.properties");
        Properties props = new Properties();
        File file = new File(path);
        if (!file.isFile()) {
            LOGGER.warn("secrets file not found: {}", file.getAbsolutePath());
            return props;
        }
        try (Reader reader = new InputStreamReader(new FileInputStream(file), StandardCharsets.UTF_8)) {
            props.load(reader);
        } catch (IOException e) {
            LOGGER.error("failed to read secrets file: {}", file.getAbsolutePath(), e);
        }
        return props;
    }
}
