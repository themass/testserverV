package com.timeline.vpn;

import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.ApplicationPidFileWriter;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;
import tk.mybatis.spring.annotation.MapperScan;

import org.springframework.core.env.Environment;

import java.util.Arrays;
import java.util.concurrent.atomic.AtomicBoolean;

@SpringBootApplication
@EnableDiscoveryClient
@EnableFeignClients(basePackages = {
        "com.timeline.vpn.*"
})
@ComponentScan(basePackages = {
        "com.timeline.vpn.*"
})
@EnableAsync
@Slf4j
@EnableConfigurationProperties
@EnableScheduling
@MapperScan(basePackages = {"com.timeline.vpn.dao.db"})
public class VVVLinkApplication implements CommandLineRunner {

    @org.springframework.beans.factory.annotation.Autowired
    private org.springframework.context.ApplicationContext context;


    private final AtomicBoolean run = new AtomicBoolean(false);

    public static void main(String[] args) {
        SpringApplication application = new SpringApplication(VVVLinkApplication.class);
        application.addListeners(new ApplicationPidFileWriter());
        application.run(args);
    }

    @Override
    public void run(String... args) throws Exception {
        if (run.compareAndSet(false, true)) {
            log.info("VVVLinkApplication start success");
            // bootstrap.yml 里 profiles.active 默认是 local（方便本地直接启动）。如果忘了显式
            // 指定 prod，服务会带着 local 的 log4j 配置和本地库地址上线，很难在运行时发现——
            // 这行日志至少让它在启动输出里显眼。
            Environment env = context.getEnvironment();
            String[] profiles = env.getActiveProfiles();
            if (profiles.length == 0 || Arrays.asList(profiles).contains("local")) {
                log.warn("当前运行的 profile={} 是本地配置；生产部署请显式指定 --spring.profiles.active=prod",
                        Arrays.toString(profiles));
            } else {
                log.info("当前运行的 profile={}", Arrays.toString(profiles));
            }
        }
    }

}
