package com.timeline.vpn.common.config;

import lombok.Data;
import lombok.ToString;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.cloud.context.config.annotation.RefreshScope;
import org.springframework.context.annotation.Configuration;


@Data
@Slf4j
@Configuration
@ConfigurationProperties(prefix = "oss")
@RefreshScope
@ToString
public class OssConfig {
    private String endpoint;
    private String region;
    private String accessKey;
    private String secretKey;
    private String bucketName;
    private String dir;
    private String cdnAddrPref;
}
