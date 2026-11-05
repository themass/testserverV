package com.timeline.roles;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.timeline.roles.api.RoleController;
import com.timeline.roles.service.RoleCatalog;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class RoleControllerTest {
    static MockMvc mvc;

    @BeforeAll
    static void setUp() {
        RoleCatalog catalog = new RoleCatalog(new ObjectMapper(), "/roles/catalog.json", "/roles/catalog-zh.json");
        mvc = MockMvcBuilders.standaloneSetup(new RoleController(catalog)).build();
    }

    @Test
    void listsDivisionsWithCounts() throws Exception {
        mvc.perform(get("/api/roles/v1/divisions"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data[0].id").isNotEmpty())
                .andExpect(jsonPath("$.data[0].count").isNumber());
    }

    @Test
    void pagesRolesAndNeverExposesPrompts() throws Exception {
        mvc.perform(get("/api/roles/v1/roles?division=engineering&limit=5"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items.length()").value(5))
                .andExpect(jsonPath("$.data.total").isNumber())
                .andExpect(jsonPath("$.data.items[0].prompt").doesNotExist());
    }

    @Test
    void rejectsOutOfRangeLimit() throws Exception {
        mvc.perform(get("/api/roles/v1/roles?limit=0")).andExpect(status().isBadRequest());
        mvc.perform(get("/api/roles/v1/roles?limit=101")).andExpect(status().isBadRequest());
        mvc.perform(get("/api/roles/v1/roles?offset=-1")).andExpect(status().isBadRequest());
    }

    @Test
    void offsetPastTheEndIsAnEmptyPageNotAnError() throws Exception {
        mvc.perform(get("/api/roles/v1/roles?offset=100000"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items.length()").value(0));
    }

    @Test
    void getsOneRoleOr404() throws Exception {
        mvc.perform(get("/api/roles/v1/roles/engineering-frontend-developer"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value("engineering-frontend-developer"));
        mvc.perform(get("/api/roles/v1/roles/nope")).andExpect(status().isNotFound());
    }
}
