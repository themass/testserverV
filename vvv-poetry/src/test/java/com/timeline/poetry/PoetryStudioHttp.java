package com.timeline.poetry;

import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** MockMvc 小工具：带令牌的请求构造 + 断言状态码后返回 JSON 树。 */
final class PoetryStudioHttp {
    static final String BASE = "/api/poetry/v1";
    static final String STUDIO = BASE + "/studio";
    static final String ORCH = BASE + "/agent-orchestration";
    static final String AGENT_HEADER = "X-Poetry-Agent-Internal-Token";
    static final String STUDIO_HEADER = "X-Poetry-Studio-Reviewer-Token";

    private final PoetryStudioFixture fx;
    PoetryStudioHttp(PoetryStudioFixture fx) { this.fx = fx; }

    static Map<String, Object> map(Object... kv) {
        Map<String, Object> m = new LinkedHashMap<>();
        for (int i = 0; i < kv.length; i += 2) m.put((String) kv[i], kv[i + 1]);
        return m;
    }

    MockHttpServletRequestBuilder studioPut(String path, Object body) throws Exception {
        return put(STUDIO + path).header(STUDIO_HEADER, PoetryStudioFixture.STUDIO_TOKEN).contentType("application/json;charset=UTF-8")
            .content(fx.json.writeValueAsString(body).getBytes(StandardCharsets.UTF_8));
    }
    MockHttpServletRequestBuilder studioPost(String path, Object body) throws Exception {
        return post(STUDIO + path).header(STUDIO_HEADER, PoetryStudioFixture.STUDIO_TOKEN).contentType("application/json;charset=UTF-8")
            .content(fx.json.writeValueAsString(body).getBytes(StandardCharsets.UTF_8));
    }
    MockHttpServletRequestBuilder agentGet(String pathAndQuery) {
        return get(ORCH + pathAndQuery).header(AGENT_HEADER, PoetryStudioFixture.AGENT_TOKEN);
    }

    /** 执行请求，断言 HTTP 状态，返回整个响应信封。 */
    JsonNode send(MockHttpServletRequestBuilder request, int expectedStatus) throws Exception {
        MvcResult result = fx.mvc.perform(request).andExpect(status().is(expectedStatus)).andReturn();
        String body = result.getResponse().getContentAsString(StandardCharsets.UTF_8);
        return body.isBlank() ? fx.json.createObjectNode() : fx.tree(body);
    }

    /** GET 并返回 data 节点。 */
    JsonNode data(String pathAndQuery, int expectedStatus) throws Exception {
        return send(agentGet(pathAndQuery), expectedStatus).path("data");
    }

    static java.util.Set<String> keys(JsonNode node) {
        java.util.Set<String> out = new java.util.TreeSet<>();
        node.fieldNames().forEachRemaining(out::add);
        return out;
    }
}
