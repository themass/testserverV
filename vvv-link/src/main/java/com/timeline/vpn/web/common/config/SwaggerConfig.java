package com.aitogether.athena.link.config;

import io.swagger.v3.oas.models.ExternalDocumentation;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.servers.Server;
import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.ArrayList;
import java.util.List;

@Data
@Configuration
@ConfigurationProperties(prefix = "swagger")
public class SwaggerConfig {
    private List<String> serverList;

    @Bean
    public OpenAPI springShopOpenAPI() {
        OpenAPI openAPI = new OpenAPI()
                .info(new Info().title("Athena API")
                        .description("AI学科")
                        .version("v0.0.1")
                        .license(new License().name("Apache 2.0").url("http://springdoc.org")))
                .externalDocs(new ExternalDocumentation()
                        .description("AI学科 Documentation")
                        .url("https://alidocs.dingtalk.com/i/nodes/14dA3GK8gjkdyBzdsjoEKaQBJ9ekBD76?doc_type=wiki_doc"));
        // 手动配置服务地址列表
        if (serverList != null && serverList.size() > 0) {
            List<Server> servers = new ArrayList<>();
            for (String server : serverList) {
                servers.add(new Server().url(server));
            }
            openAPI.servers(servers);
        }
        return openAPI;
    }

}
