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
        }
    }

}
