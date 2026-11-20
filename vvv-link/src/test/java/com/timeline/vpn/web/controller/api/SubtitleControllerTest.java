package com.timeline.vpn.web.controller.api;

import com.timeline.vpn.common.exception.BusinessException;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.DevApp;
import com.timeline.vpn.model.param.PageBaseParam;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.SubtitleContentVo;
import com.timeline.vpn.model.vo.SubtitleVo;
import com.timeline.vpn.service.DataSubtitleService;
import com.timeline.vpn.web.common.CommonHandlerExceptionResolver;
import com.timeline.vpn.web.common.DevAppContext;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * 字幕接口契约测试：standaloneSetup + 假 Service，纯 JUnit 5，不起 Spring 容器、不连库。
 *
 * <p>契约要点：列表只出 id/title/lang/format/size，绝不出现 content；
 * item.json 命中出 {id, content}，未命中走 BusinessException → errno 11003（≠0）。
 */
class SubtitleControllerTest {
    private FakeSubtitleService service;
    private MockMvc mvc;

    /** 假 Service：回放固定数据，同时记录入参，验证 form → param 的透传没有被加工。 */
    static class FakeSubtitleService implements DataSubtitleService {
        long videoId;
        PageBaseParam param;
        long contentId;

        @Override
        public InfoListVo<SubtitleVo> getSubtitlePage(BaseQuery baseQuery, PageBaseParam param,
                long videoId) {
            this.videoId = videoId;
            this.param = param;
            SubtitleVo vo = new SubtitleVo();
            vo.setId(7);
            vo.setTitle("简体中文");
            vo.setLang("zh");
            vo.setFormat("srt");
            vo.setSize(1024L);
            InfoListVo<SubtitleVo> page = new InfoListVo<>();
            page.setVoList(List.of(vo));
            page.setTotal(42);
            page.setHasMore(true);
            page.setPageNum(2);
            return page;
        }

        @Override
        public SubtitleContentVo getSubtitleContent(BaseQuery baseQuery, long id) {
            this.contentId = id;
            if (id == 404L) {
                throw new BusinessException("字幕不存在");
            }
            SubtitleContentVo vo = new SubtitleContentVo();
            vo.setId(id);
            vo.setContent("1\n00:00:01,000 --> 00:00:02,000\n你好\n");
            return vo;
        }
    }

    @BeforeEach
    void setUp() {
        // JsonResult.getData() 依赖 DevAppContext：isTest=true 时 data 原样下发（不 AES），
        // 测试断言才能直接打在 $.data.* 上。
        DevApp app = new DevApp();
        app.setTest(true);
        DevAppContext.set(app);
        service = new FakeSubtitleService();
        mvc = MockMvcBuilders.standaloneSetup(new SubtitleController(service))
                // BusinessException → errno 11003 的映射在生产里由这个 advice 完成，测试要复现它
                .setControllerAdvice(new CommonHandlerExceptionResolver())
                .build();
    }

    @AfterEach
    void tearDown() {
        DevAppContext.set(null);
    }

    @Test
    void listsSubtitlesWithoutContentField() throws Exception {
        mvc.perform(get("/api/video/subtitle/items.json").param("id", "123")
                        .param("start", "0").param("limit", "20")
                        .header("User-Agent", "junit"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.errno").value(0))
                .andExpect(jsonPath("$.data.voList[0].id").value(7))
                .andExpect(jsonPath("$.data.voList[0].title").value("简体中文"))
                .andExpect(jsonPath("$.data.voList[0].lang").value("zh"))
                .andExpect(jsonPath("$.data.voList[0].format").value("srt"))
                .andExpect(jsonPath("$.data.voList[0].size").value(1024))
                .andExpect(jsonPath("$.data.total").value(42))
                .andExpect(jsonPath("$.data.hasMore").value(true))
                .andExpect(jsonPath("$.data.pageNum").value(2))
                // 契约红线：列表绝不带 content
                .andExpect(jsonPath("$.data.voList[0].content").doesNotExist());
        assertEquals(123L, service.videoId);
        assertEquals(0, service.param.getStart());
        // PageBaseForm.setLimit 会把 < MIN_PAGESIZE(30) 的请求夹到 30 —— 跟老接口一致，原样断言
        assertEquals(30, service.param.getLimit());
    }

    @Test
    void itemsAcceptsPostToo() throws Exception {
        mvc.perform(post("/api/video/subtitle/items.json").param("id", "1").param("start", "60")
                        .param("limit", "20").header("User-Agent", "junit"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.errno").value(0));
        assertEquals(60, service.param.getStart());
    }

    @Test
    void returnsWholeSubtitleTextOnHit() throws Exception {
        mvc.perform(get("/api/video/subtitle/item.json").param("id", "9")
                        .header("User-Agent", "junit"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.errno").value(0))
                .andExpect(jsonPath("$.data.id").value(9))
                .andExpect(jsonPath("$.data.content").value("1\n00:00:01,000 --> 00:00:02,000\n你好\n"));
        assertEquals(9L, service.contentId);
    }

    @Test
    void missingSubtitleIsBusinessErrorNotSuccess() throws Exception {
        mvc.perform(get("/api/video/subtitle/item.json").param("id", "404")
                        .header("User-Agent", "junit"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.errno").value(com.timeline.vpn.Constant.ResultErrno.ERRNO_BUSINESS))
                .andExpect(jsonPath("$.errno").value(org.hamcrest.Matchers.not(0)))
                .andExpect(jsonPath("$.error").value("字幕不存在"));
    }
}
