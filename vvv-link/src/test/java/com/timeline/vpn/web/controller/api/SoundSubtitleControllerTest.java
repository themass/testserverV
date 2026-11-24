package com.timeline.vpn.web.controller.api;

import com.timeline.vpn.Constant;
import com.timeline.vpn.common.exception.BusinessException;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.DevApp;
import com.timeline.vpn.model.po.UserPo;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.SoundSubtitleContentVo;
import com.timeline.vpn.model.vo.SoundSubtitleGenerateVo;
import com.timeline.vpn.model.vo.SubtitleVo;
import com.timeline.vpn.service.DataSoundSubtitleService;
import com.timeline.vpn.web.common.CommonHandlerExceptionResolver;
import com.timeline.vpn.web.common.DevAppContext;
import com.timeline.vpn.web.common.resolver.UserInfoArgumentResolver;
import com.timeline.vpn.web.common.resolver.UserInfoResolver;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * 声音馆歌词接口契约测试（契约 sound-lyrics-contract §2 Phase 1/2）：
 * standaloneSetup + 假 Service，纯 JUnit 5，不起 Spring 容器、不连库。
 *
 * <p>契约红线（Android 端 ScreeningFeedStore.soundSubtitles/soundSubtitleContent 逐字依赖）：
 * ① items.json 只出 id/title/lang/format/size，绝不出现 content；
 * ② 无轨回空列表 errno=0（不是错误）——端上据此走实时 ASR 兜底；
 * ③ item.json 出 {id,content,format,lang}，未命中 errno=11003；
 * ④ generate.json 必须登录（无 token → errno=11001），返回 {genStatus,started}。
 *
 * <p>@UserInfo 用真实解析器（生产同款 UserInfoResolver）：登录态由
 * Vpn-Token 头 + 拦截器落在 request 上的 Constant.HTTP_ATTR_TOKEN 决定，测试用 requestAttr 复现。
 */
class SoundSubtitleControllerTest {
    private FakeSoundSubtitleService service;
    private MockMvc mvc;

    /** 假 Service：回放固定数据并记录入参，验证 controller → service 的透传没被加工。 */
    static class FakeSoundSubtitleService implements DataSoundSubtitleService {
        long listSoundItemId = -1;
        long contentId = -1;
        long generateSoundItemId = -1;
        boolean emptyList;
        BaseQuery generateQuery;

        @Override
        public InfoListVo<SubtitleVo> getSoundSubtitleList(BaseQuery baseQuery, long soundItemId) {
            this.listSoundItemId = soundItemId;
            InfoListVo<SubtitleVo> page = new InfoListVo<>();
            if (!emptyList) {
                SubtitleVo vo = new SubtitleVo();
                vo.setId(11);
                vo.setTitle("夜航西飞");
                vo.setLang("zh");
                vo.setFormat("srt");
                vo.setSize(2048L);
                page.setVoList(List.of(vo));
                page.setTotal(1);
            }
            return page;
        }

        @Override
        public SoundSubtitleContentVo getSoundSubtitleContent(BaseQuery baseQuery, long id) {
            this.contentId = id;
            if (id == 404L) {
                throw new BusinessException("歌词不存在");
            }
            SoundSubtitleContentVo vo = new SoundSubtitleContentVo();
            vo.setId(id);
            vo.setContent("1\n00:00:01,000 --> 00:00:02,000\n你好\n");
            vo.setFormat("srt");
            vo.setLang("zh");
            return vo;
        }

        @Override
        public SoundSubtitleGenerateVo requestGeneration(BaseQuery baseQuery, long soundItemId) {
            this.generateSoundItemId = soundItemId;
            this.generateQuery = baseQuery;
            SoundSubtitleGenerateVo vo = new SoundSubtitleGenerateVo();
            vo.setGenStatus("running");
            vo.setStarted(true);
            return vo;
        }
    }

    @BeforeEach
    void setUp() {
        // isTest=true：JsonResult.getData() 原样下发（不 AES），断言直接打在 $.data.* 上。
        // tokenHeader 设成生产 VVV 客户端的口径，登录测试的 header 名跟着它。
        DevApp app = new DevApp();
        app.setTest(true);
        app.setTokenHeader(Constant.HTTP_TOKEN_KEY);
        DevAppContext.set(app);

        service = new FakeSoundSubtitleService();
        UserInfoArgumentResolver resolver = new UserInfoArgumentResolver();
        ReflectionTestUtils.setField(resolver, "userInfoResolver", new UserInfoResolver());
        mvc = MockMvcBuilders.standaloneSetup(new SoundSubtitleController(service))
                .setControllerAdvice(new CommonHandlerExceptionResolver())
                .setCustomArgumentResolvers(resolver)
                .build();
    }

    @AfterEach
    void tearDown() {
        DevAppContext.set(null);
    }

    private UserPo loginUser() {
        UserPo user = new UserPo();
        user.setId(7);
        user.setName("gqli");
        return user;
    }

    @Test
    void listsSoundSubtitlesWithoutContentField() throws Exception {
        mvc.perform(get("/api/sound/subtitle/items.json").param("soundItemId", "123")
                        .header("User-Agent", "junit"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.errno").value(0))
                .andExpect(jsonPath("$.data.voList[0].id").value(11))
                .andExpect(jsonPath("$.data.voList[0].title").value("夜航西飞"))
                .andExpect(jsonPath("$.data.voList[0].lang").value("zh"))
                .andExpect(jsonPath("$.data.voList[0].format").value("srt"))
                .andExpect(jsonPath("$.data.voList[0].size").value(2048))
                // 契约红线：列表绝不带 content
                .andExpect(jsonPath("$.data.voList[0].content").doesNotExist());
        assertEquals(123L, service.listSoundItemId);
    }

    @Test
    void noTrackIsEmptyListNotError() throws Exception {
        service.emptyList = true;
        // 不断言 $.data.voList 是空数组：JsonUtil 关掉了 WRITE_EMPTY_JSON_ARRAYS，
        // 空列表可能被整个省略。契约要保证的是「errno=0 且没有条目」。
        mvc.perform(get("/api/sound/subtitle/items.json").param("soundItemId", "999")
                        .header("User-Agent", "junit"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.errno").value(0))
                .andExpect(jsonPath("$.data.voList[0]").doesNotExist());
    }

    @Test
    void returnsWholeLyricsTextWithFormatAndLangOnHit() throws Exception {
        mvc.perform(get("/api/sound/subtitle/item.json").param("id", "9")
                        .header("User-Agent", "junit"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.errno").value(0))
                .andExpect(jsonPath("$.data.id").value(9))
                .andExpect(jsonPath("$.data.content").value("1\n00:00:01,000 --> 00:00:02,000\n你好\n"))
                .andExpect(jsonPath("$.data.format").value("srt"))
                .andExpect(jsonPath("$.data.lang").value("zh"));
        assertEquals(9L, service.contentId);
    }

    @Test
    void missingLyricsIsBusinessErrorNotSuccess() throws Exception {
        mvc.perform(get("/api/sound/subtitle/item.json").param("id", "404")
                        .header("User-Agent", "junit"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.errno").value(Constant.ResultErrno.ERRNO_BUSINESS))
                .andExpect(jsonPath("$.errno").value(org.hamcrest.Matchers.not(0)))
                .andExpect(jsonPath("$.error").value("歌词不存在"));
    }

    @Test
    void generateRequiresLogin() throws Exception {
        // 不带 token：真实 UserInfoResolver 抛 LoginException（生产同款路径），service 根本不该被触达
        mvc.perform(post("/api/sound/subtitle/generate.json").param("soundItemId", "123")
                        .header("User-Agent", "junit"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.errno").value(Constant.ResultErrno.ERRNO_PWD))
                .andExpect(jsonPath("$.errno").value(org.hamcrest.Matchers.not(0)));
        assertEquals(-1L, service.generateSoundItemId);
    }

    @Test
    void generateStartedReturnsStatusWhenLoggedIn() throws Exception {
        mvc.perform(post("/api/sound/subtitle/generate.json").param("soundItemId", "123")
                        .header("User-Agent", "junit")
                        .header(Constant.HTTP_TOKEN_KEY, "tok-1")
                        .requestAttr(Constant.HTTP_ATTR_TOKEN, loginUser()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.errno").value(0))
                .andExpect(jsonPath("$.data.genStatus").value("running"))
                .andExpect(jsonPath("$.data.started").value(true));
        assertEquals(123L, service.generateSoundItemId);
        // 登录用户要能透传到 service（审计/限流后置靠它）
        assertEquals(7L, service.generateQuery.getUser().getId());
    }

    @Test
    void itemsAcceptsPostToo() throws Exception {
        mvc.perform(post("/api/sound/subtitle/items.json").param("soundItemId", "5")
                        .header("User-Agent", "junit"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.errno").value(0));
        assertEquals(5L, service.listSoundItemId);
    }
}
