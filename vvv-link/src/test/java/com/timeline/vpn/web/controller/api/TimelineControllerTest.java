package com.timeline.vpn.web.controller.api;

import com.timeline.vpn.Constant;
import com.timeline.vpn.common.exception.BusinessException;
import com.timeline.vpn.model.po.UserPo;
import com.timeline.vpn.model.vo.TimelineCommentVo;
import com.timeline.vpn.model.vo.TimelinePostVo;
import com.timeline.vpn.model.vo.TimelineWindowVo;
import com.timeline.vpn.service.CacheService;
import com.timeline.vpn.service.DataDanmakuService;
import com.timeline.vpn.web.common.CommonHandlerExceptionResolver;
import com.timeline.vpn.web.common.DevAppContext;
import com.timeline.vpn.model.param.DevApp;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * 弹幕接口契约测试：standaloneSetup + 假 Service/Cache，纯 JUnit 5，不起 Spring 容器、不连库。
 *
 * <p>契约红线（app 端 HttpDanmakuSource 逐字依赖）：
 * 信封 {errno, data, error} 明文；窗口 data = {comments:[{id,atMs,text,author}], nextCursor}；
 * 发送 data = {comment:{…}}；未登录 errno=2；业务拒绝 errno=11003 + error 文案。
 *
 * <p>每个请求都带 User-Agent：advice 的第一行 HttpCommonUtil.getUA() 对 null UA 直接 NPE
 * （SubtitleControllerTest 同样全部带 "junit" UA），真机上 OkHttp 恒带 okhttp/… UA，不是生产问题。
 */
class TimelineControllerTest {
    private FakeDanmakuService service;
    private MockMvc mvc;

    /** 假 Service：回放固定数据并记录入参，验证 controller → service 的透传没被加工。 */
    static class FakeDanmakuService implements DataDanmakuService {
        String namespace, contentId, editionId;
        long startMs, endMs;
        Long cursor;
        int limit;
        Long postUserId;
        String postAuthor, postClientMsgId, postText;
        Long postAtMs;
        Long retractId, retractUserId;
        boolean throwOnRetract;

        @Override
        public TimelineWindowVo getWindow(String namespace, String contentId, String editionId,
                long startMs, long endMs, Long cursor, int limit) {
            this.namespace = namespace;
            this.contentId = contentId;
            this.editionId = editionId;
            this.startMs = startMs;
            this.endMs = endMs;
            this.cursor = cursor;
            this.limit = limit;
            TimelineCommentVo c = new TimelineCommentVo();
            c.setId(4001);
            c.setAtMs(9000);
            c.setText("你好");
            c.setAuthor("gqli");
            TimelineWindowVo vo = new TimelineWindowVo();
            vo.setComments(List.of(c));
            vo.setNextCursor("4001");
            return vo;
        }

        @Override
        public TimelinePostVo post(String namespace, String contentId, String editionId,
                long userId, String authorName, String clientMessageId, long atMs, String text) {
            this.postUserId = userId;
            this.postAuthor = authorName;
            this.postClientMsgId = clientMessageId;
            this.postAtMs = atMs;
            this.postText = text;
            TimelineCommentVo c = new TimelineCommentVo();
            c.setId(4002);
            c.setAtMs(atMs);
            c.setText(text);
            c.setAuthor(authorName);
            TimelinePostVo vo = new TimelinePostVo();
            vo.setComment(c);
            return vo;
        }

        @Override
        public void retract(long commentId, long userId) {
            this.retractId = commentId;
            this.retractUserId = userId;
            if (throwOnRetract) {
                throw new BusinessException("只能撤回自己的弹幕");
            }
        }
    }

    /** 假 Cache：只认 token "tok-ok" → userId 7 / name gqli；其余一律 null（未登录）。 */
    static class FakeCache implements CacheService {
        @Override
        public UserPo getUser(String token) {
            if (!"tok-ok".equals(token)) {
                return null;
            }
            UserPo user = new UserPo();
            user.setId(7);
            user.setName("gqli");
            return user;
        }

        @Override
        public String getToken(String name) {
            return null;
        }

        @Override
        public String putUser(UserPo user) {
            return null;
        }

        @Override
        public String updateUser(String token, UserPo user) {
            return null;
        }

        @Override
        public int updateCount(UserPo user) {
            return 0;
        }

        @Override
        public void del(String token) {}

        @Override
        public void put(String key, String val, long timeout) {}

        @Override
        public String get(String key) {
            return null;
        }

        @Override
        public Long lock(String lockKey) {
            return null;
        }

        @Override
        public void unlock(String lockKey) {}
    }

    @BeforeEach
    void setUp() {
        // 业务异常会落到 advice 返回的 JsonResult；its getData() 读 DevAppContext，
        // isTest=true 时不 AES——成功路径用的是 TimelineResult，本来就不碰这个上下文。
        DevApp app = new DevApp();
        app.setTest(true);
        DevAppContext.set(app);
        service = new FakeDanmakuService();
        mvc = MockMvcBuilders.standaloneSetup(new TimelineController(service, new FakeCache()))
                .setControllerAdvice(new CommonHandlerExceptionResolver())
                .build();
    }

    @AfterEach
    void tearDown() {
        DevAppContext.set(null);
    }

    /** 统一补 UA 头（advice 对 null UA NPE），perform 一律走这里。 */
    private org.springframework.test.web.servlet.ResultActions perform(MockHttpServletRequestBuilder builder)
            throws Exception {
        return mvc.perform(builder.header("User-Agent", "junit"));
    }

    @Test
    void getWindowServesPlaintextEnvelope() throws Exception {
        perform(get("/api/timeline/v1/local/demo/v1/comments")
                        .param("startMs", "8000").param("endMs", "16000")
                        .param("limit", "200"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.errno").value(0))
                .andExpect(jsonPath("$.data.comments[0].id").value(4001))
                .andExpect(jsonPath("$.data.comments[0].atMs").value(9000))
                .andExpect(jsonPath("$.data.comments[0].text").value("你好"))
                .andExpect(jsonPath("$.data.comments[0].author").value("gqli"))
                .andExpect(jsonPath("$.data.nextCursor").value("4001"));
        assertEquals("local", service.namespace);
        assertEquals("demo", service.contentId);
        assertEquals("v1", service.editionId);
        assertEquals(8000, service.startMs);
        assertEquals(16000, service.endMs);
        assertNull(service.cursor);
        assertEquals(200, service.limit);
    }

    @Test
    void cursorPassesThroughAsLong() throws Exception {
        perform(get("/api/timeline/v1/local/demo/v1/comments")
                        .param("startMs", "0").param("endMs", "8000").param("cursor", "4001"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.errno").value(0));
        assertEquals(4001L, service.cursor);
    }

    @Test
    void badWindowOrCursorIsParamError() throws Exception {
        perform(get("/api/timeline/v1/local/demo/v1/comments")
                        .param("startMs", "9000").param("endMs", "8000"))
                .andExpect(jsonPath("$.errno").value(Constant.ResultErrno.ERRNO_PARAM));
        perform(get("/api/timeline/v1/local/demo/v1/comments")
                        .param("startMs", "0").param("endMs", "8000").param("cursor", "abc"))
                .andExpect(jsonPath("$.errno").value(Constant.ResultErrno.ERRNO_PARAM));
        // path 段字符集外的值（"b+d"）也按参数错误处理，不进 service
        perform(get("/api/timeline/v1/local/b+d/v1/comments")
                        .param("startMs", "0").param("endMs", "8000"))
                .andExpect(jsonPath("$.errno").value(Constant.ResultErrno.ERRNO_PARAM));
    }

    @Test
    void getWorksWithoutLogin() throws Exception {
        perform(get("/api/timeline/v1/local/demo/v1/comments")
                        .param("startMs", "0").param("endMs", "8000"))
                .andExpect(jsonPath("$.errno").value(0));
    }

    @Test
    void postWithoutTokenNeedsLogin() throws Exception {
        perform(post("/api/timeline/v1/local/demo/v1/comments")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"clientMessageId\":\"k#1\",\"atMs\":9000,\"text\":\"你好\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.errno").value(Constant.ResultErrno.ERRNO_NEED_LOGIN));
    }

    @Test
    void postEchoesCommentAndPassesUserThrough() throws Exception {
        perform(post("/api/timeline/v1/local/demo/v1/comments")
                        .header("Authorization", "Bearer tok-ok")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"clientMessageId\":\"local:demo:v1#1\",\"atMs\":9000,\"text\":\" 你好 \"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.errno").value(0))
                .andExpect(jsonPath("$.data.comment.id").value(4002))
                .andExpect(jsonPath("$.data.comment.atMs").value(9000))
                .andExpect(jsonPath("$.data.comment.text").value("你好"))
                .andExpect(jsonPath("$.data.comment.author").value("gqli"));
        assertEquals(7L, service.postUserId);
        assertEquals("gqli", service.postAuthor);
        assertEquals("local:demo:v1#1", service.postClientMsgId);
        assertEquals(9000L, service.postAtMs);
        // controller 负责 trim，service 收到的就是净文本
        assertEquals("你好", service.postText);
    }

    @Test
    void blankOrOverlongTextIsParamError() throws Exception {
        perform(post("/api/timeline/v1/local/demo/v1/comments")
                        .header("Authorization", "Bearer tok-ok")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"clientMessageId\":\"k#1\",\"atMs\":0,\"text\":\"   \"}"))
                .andExpect(jsonPath("$.errno").value(Constant.ResultErrno.ERRNO_PARAM));
        String long101 = "字".repeat(101);
        perform(post("/api/timeline/v1/local/demo/v1/comments")
                        .header("Authorization", "Bearer tok-ok")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"clientMessageId\":\"k#1\",\"atMs\":0,\"text\":\"" + long101 + "\"}"))
                .andExpect(jsonPath("$.errno").value(Constant.ResultErrno.ERRNO_PARAM));
    }

    @Test
    void businessErrorSurfacesAsErrno11003WithMessage() throws Exception {
        // 限频/归属这类 service 拒绝的等价场景：BusinessException → advice 映射 errno 11003 + 文案
        service.throwOnRetract = true;
        perform(delete("/api/timeline/v1/local/demo/v1/comments/4002")
                        .header("Authorization", "Bearer tok-ok"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.errno").value(Constant.ResultErrno.ERRNO_BUSINESS))
                .andExpect(jsonPath("$.error").value("只能撤回自己的弹幕"))
                .andExpect(jsonPath("$.data").doesNotExist());
    }

    @Test
    void retractRequiresLoginThenCarriesUserId() throws Exception {
        perform(delete("/api/timeline/v1/local/demo/v1/comments/4002"))
                .andExpect(jsonPath("$.errno").value(Constant.ResultErrno.ERRNO_NEED_LOGIN));
        perform(delete("/api/timeline/v1/local/demo/v1/comments/4002")
                        .header("Authorization", "Bearer tok-ok"))
                .andExpect(jsonPath("$.errno").value(0))
                // app 端 request() 要求 data 非 null：撤回成功也得给个对象
                .andExpect(jsonPath("$.data").exists());
        assertEquals(4002L, service.retractId);
        assertEquals(7L, service.retractUserId);
    }
}
