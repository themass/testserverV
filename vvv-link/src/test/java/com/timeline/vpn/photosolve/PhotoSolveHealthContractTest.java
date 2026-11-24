package com.timeline.vpn.photosolve;

import com.timeline.vpn.model.param.DevApp;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.photosolve.model.PhotoSolveResponse;
import com.timeline.vpn.web.common.CommonHandlerExceptionResolver;
import com.timeline.vpn.web.common.DevAppContext;
import com.timeline.vpn.web.common.config.WebConfig;
import com.timeline.vpn.web.common.interceptor.BlackdevHandlerInterceptor;
import com.timeline.vpn.web.common.interceptor.UserCheckHandlerInterceptor;
import com.timeline.vpn.web.common.interceptor.VersionHandlerInterceptor;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.handler.MappedInterceptor;

import java.lang.reflect.Field;
import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

/**
 * health.json 的契约测试 + 生产 errno=10000 的复现（Design-3 报告：POST 返回 errno 10000，
 * GET 返回 method-not-supported）。
 *
 * <p>诊断链（源码证据，均为本仓文件）：
 * <ol>
 *   <li>{@link PhotoSolveController} 的类注释写 {@code GET /health.json}，但方法是
 *       {@code @PostMapping} → GET 落到 {@link CommonHandlerExceptionResolver} 的
 *       HttpRequestMethodNotSupportedException 分支 → errno 11002「method not supported」，
 *       与 Design-3 观察一致。</li>
 *   <li>POST 能进拦截器链：HostFilter（url-pattern {@code *.json}）对无签名 UA 调
 *       {@code DeviceUtil.getAPPInfo} 返回 null → {@code DevAppContext.set(null)}；
 *       {@link UserCheckHandlerInterceptor#preHandle} 见 app==null 直接
 *       {@code throw new RuntimeException("welcome")} → 全局兜底 else 分支
 *       {@code ERRNO_SYSTEM=10000} + "System error，please try again"。
 *       这正是生产的 errno=10000：部署自检（裸 curl）根本走不到 health 方法本身。</li>
 * </ol>
 */
class PhotoSolveHealthContractTest {

    /** 假 provider：health 只调 name()/isAvailable()，不碰网络。 */
    static class FakeProvider implements PhotoSolveProvider {
        @Override
        public String name() {
            return "fake-ep";
        }

        @Override
        public boolean isAvailable() {
            return true;
        }

        @Override
        public PhotoSolveResponse solve(List<byte[]> images, List<String> mimeTypes, String text,
                                        String subject, String grade, String requestId) {
            throw new UnsupportedOperationException();
        }
    }

    private MockMvc mvc;

    /** 能读出每条拦截器注册的 excludePatterns（InterceptorRegistry.getInterceptors 是 protected）。 */
    static class TestRegistry extends InterceptorRegistry {
        List<Object> registrations() {
            return getInterceptors();
        }
    }

    private static void inject(Object target, String field, Object value) throws Exception {
        Field f = target.getClass().getDeclaredField(field);
        f.setAccessible(true);
        f.set(target, value);
    }

    @BeforeEach
    void setUp() {
        mvc = MockMvcBuilders.standaloneSetup(new PhotoSolveController(new FakeProvider(), null))
                .setControllerAdvice(new CommonHandlerExceptionResolver())
                .build();
    }

    @AfterEach
    void tearDown() {
        DevAppContext.set(null);
    }

    // ---- 生产故障复现：无签名 UA 的裸 POST，进不到 controller ----

    @Test
    void unsignedPostHitsUserCheckWelcomeAndBecomes10000() throws Exception {
        // 复现（并钉住诊断结论）：HostFilter 对无签名 UA 得到 DevApp=null（DeviceUtil
        // getAPPInfo 匹配不到 VVV/x.y.z.w 正则返回 null），UserCheckHandlerInterceptor
        // 见 null 抛 RuntimeException("welcome") → 兜底 errno 10000。
        // 生产的 POST /health.json → 200 + errno=10000 就是这条路径，health 方法本身没执行。
        DevAppContext.set(null);
        MockMvc chained = MockMvcBuilders.standaloneSetup(new PhotoSolveController(new FakeProvider(), null))
                .setControllerAdvice(new CommonHandlerExceptionResolver())
                .addInterceptors(new UserCheckHandlerInterceptor())
                .build();
        chained.perform(post("/api/photosolve/v1/health.json").header("User-Agent", "curl/8.0"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.errno").value(10000));
    }

    @Test
    void userCheckThrowsWelcomeWhenContextNull() throws Exception {
        // 单独钉住抛点：UserCheckHandlerInterceptor.preHandle 的 RuntimeException("welcome")。
        DevAppContext.set(null);
        org.junit.jupiter.api.Assertions.assertThrows(RuntimeException.class,
                () -> new UserCheckHandlerInterceptor().preHandle(
                        new org.springframework.mock.web.MockHttpServletRequest(),
                        new org.springframework.mock.web.MockHttpServletResponse(), new Object()));
    }

    // ---- 契约：health 是部署自检，GET/POST 都要能用（类注释写的是 GET）----

    private void withTestApp() {
        DevApp app = new DevApp();
        app.setTest(true); // isTest=true：JsonResult.getData 原样下发，不 AES
        DevAppContext.set(app);
    }

    @Test
    void healthAnswersGetPerDoc() throws Exception {
        withTestApp();
        mvc.perform(get("/api/photosolve/v1/health.json").header("User-Agent", "junit"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.errno").value(0))
                .andExpect(jsonPath("$.data.provider").value("fake-ep"))
                .andExpect(jsonPath("$.data.configured").value(true))
                .andExpect(jsonPath("$.data.maxImages").value(4));
    }

    @Test
    void healthStillAnswersPost() throws Exception {
        withTestApp();
        mvc.perform(post("/api/photosolve/v1/health.json").header("User-Agent", "junit"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.errno").value(0))
                .andExpect(jsonPath("$.data.provider").value("fake-ep"));
    }

    // ---- 修复钉：health 必须被签名/黑名单/版本拦截器排除，裸 curl 才能做部署自检 ----

    @Test
    void healthIsExcludedFromSigningInterceptors() throws Exception {
        WebConfig config = new WebConfig();
        UserCheckHandlerInterceptor userCheck = new UserCheckHandlerInterceptor();
        VersionHandlerInterceptor version = new VersionHandlerInterceptor();
        BlackdevHandlerInterceptor blackdev = new BlackdevHandlerInterceptor();
        inject(config, "userCheckHandlerInterceptor", userCheck);
        inject(config, "versionHandlerInterceptor", version);
        inject(config, "blackdevHandlerInterceptor", blackdev);
        inject(config, "costHandlerInterceptor",
                new com.timeline.vpn.web.common.interceptor.CostHandlerInterceptor());

        TestRegistry registry = new TestRegistry();
        config.addInterceptors(registry);

        int checked = 0;
        for (Object reg : registry.registrations()) {
            if (!(reg instanceof MappedInterceptor mapped)) {
                continue;
            }
            Object handler = mapped.getInterceptor();
            if (handler == userCheck || handler == version || handler == blackdev) {
                checked++;
                assertTrue(Arrays.asList(mapped.getExcludePathPatterns())
                                .contains("/api/photosolve/v1/health.json"),
                        handler.getClass().getSimpleName() + " 必须排除 health.json，"
                                + "否则部署自检（无签名 UA）被拦死成 errno 10000");
            }
        }
        org.junit.jupiter.api.Assertions.assertEquals(3, checked, "三条签名拦截器都要检查到");
    }

    // ---- 修复钉：DevAppContext 为 null 时 getData 不能 NPE（排除拦截器后 success 响应要能序列化）----

    @Test
    void jsonResultDataSurvivesNullContext() {
        DevAppContext.set(null);
        JsonResult result = new JsonResult(java.util.Map.of("configured", true));
        Object data = result.getData();
        assertNotNull(data, "data 非空但 DevAppContext=null 时不能 NPE 成 errno 10000");
        assertTrue(data instanceof java.util.Map);
    }
}
