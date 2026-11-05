package com.timeline.roles.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.timeline.roles.api.RoleController;
import com.timeline.roles.service.RoleCatalog;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;

/** On by default; set roles.enabled=false to turn the catalog and its endpoints off. */
@AutoConfiguration
@ConditionalOnProperty(prefix = "roles", name = "enabled", havingValue = "true", matchIfMissing = true)
@Import(RoleController.class)
public class RolesAutoConfiguration {
    @Bean
    public RoleCatalog roleCatalog() {
        return new RoleCatalog(new ObjectMapper(), "/roles/catalog.json", "/roles/catalog-zh.json");
    }
}
