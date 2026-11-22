package com.timeline.vpn.web.controller.api;

import com.timeline.vpn.Constant;
import com.timeline.vpn.exception.LoginException;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.DevApp;
import com.timeline.vpn.model.vo.UserVo;
import com.timeline.vpn.service.UserService;

import java.util.concurrent.atomic.AtomicReference;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Mockito;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * /api/game/v1/login 契约测试（standaloneSetup + Mockito 假 UserService，不起容器不连库）：
 * ①成功：JSON body → errno 0 + data{token,name}，且 BaseQuery.appInfo 被手工构造齐备
 *   （channel/devId/platform/version/ua 全非空——login() 与 updateDevUseinfo 的必达字段）；
 * ②密码错：LoginException → errno 11001 + 中文 error（不透出 key，也不泄露账号存在性）；
 * ③参数缺失：errno 非 0，不触达 UserService。
 */
class GameLoginControllerTest {

    private UserService userService;
    private MockMvc mvc;
    private final AtomicReference<BaseQuery> captured = new AtomicReference<>();

    @BeforeEach
    void setUp() {
        userService = Mockito.mock(UserService.class);
        mvc = MockMvcBuilders.standaloneSetup(new GameLoginController(userService)).build();
    }

    private UserVo okVo() {
        UserVo vo = new UserVo();
        vo.setName("tom");
        vo.setToken("token_RAWTOKEN123");   // putUser 原样返回（完整键形态）
        return vo;
    }

    @Test
    void loginSuccessReturnsTokenAndNameAndBuildsDevApp() throws Exception {
        Mockito.when(userService.login(any(BaseQuery.class), eq("tom"), eq("pwd123"), isNull()))
            .thenAnswer(inv -> {
                captured.set(inv.getArgument(0));
                return okVo();
            });

        mvc.perform(post("/api/game/v1/login")
                .contentType(MediaType.APPLICATION_JSON)
                .header("user-agent", "Mozilla/5.0 game-h5")
                .header("X-forwarded-for", "203.0.113.9")
                .content("{\"name\":\"tom\",\"pwd\":\"pwd123\"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.errno").value(0))
            .andExpect(jsonPath("$.data.token").value("token_RAWTOKEN123"))
            .andExpect(jsonPath("$.data.name").value("tom"))
            // 出网最小面：不许带 pwd 旧字段/积分等设备信息
            .andExpect(jsonPath("$.data.areaMi").doesNotExist())
            .andExpect(jsonPath("$.data.stateUse").doesNotExist());

        BaseQuery q = captured.get();
        assertNotNull(q);
        DevApp app = q.getAppInfo();
        assertNotNull(app);
        assertEquals(Constant.VPN, app.getChannel());
        assertEquals("web", app.getPlatform());
        assertEquals("203.0.113.9", app.getUserIp());
        assertEquals("Mozilla/5.0 game-h5", app.getUa());
        assertNotNull(app.getVersion());
        Integer.parseInt(app.getVersion());            // isDog 分支会 Integer.valueOf，必须是数字
        org.junit.jupiter.api.Assertions.assertTrue(app.getDevId().startsWith("web-"));
        org.junit.jupiter.api.Assertions.assertEquals("Vpn-Token", app.getTokenHeader());
    }

    /** ua 头缺失也不能给 null（updateDevUseinfo 对 ua 做 substring 会 NPE）。 */
    @Test
    void missingUserAgentFallsBack() throws Exception {
        Mockito.when(userService.login(any(BaseQuery.class), any(), any(), isNull()))
            .thenAnswer(inv -> {
                captured.set(inv.getArgument(0));
                return okVo();
            });
        mvc.perform(post("/api/game/v1/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"tom\",\"pwd\":\"pwd123\"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.errno").value(0));
        assertNotNull(captured.get().getAppInfo().getUa());
        assertNotNull(captured.get().getAppInfo().getDevId());
    }

    @Test
    void wrongPasswordMapsToChineseError() throws Exception {
        Mockito.when(userService.login(any(BaseQuery.class), any(), any(), isNull()))
            .thenThrow(new LoginException(Constant.ResultMsg.RESULT_PWD_ERROR));

        mvc.perform(post("/api/game/v1/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"tom\",\"pwd\":\"bad\"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.errno").value(Constant.ResultErrno.ERRNO_PWD))
            .andExpect(jsonPath("$.error").value("用户名或密码错误"))
            .andExpect(jsonPath("$.data").doesNotExist());
    }

    @Test
    void blankParamsRejectedWithoutTouchingService() throws Exception {
        mvc.perform(post("/api/game/v1/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"\",\"pwd\":\"x\"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.errno").value(Constant.ResultErrno.ERRNO_PARAM));

        mvc.perform(post("/api/game/v1/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.errno").value(Constant.ResultErrno.ERRNO_PARAM));

        mvc.perform(post("/api/game/v1/login")
                .contentType(MediaType.APPLICATION_JSON))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.errno").value(Constant.ResultErrno.ERRNO_PARAM));

        Mockito.verifyNoInteractions(userService);
    }

    /** ArgumentCaptor 版本单独走一遍：确认 name/pwd 原样透传，没有被 trim 之外的加工。 */
    @Test
    void passesNameAndPwdThrough() throws Exception {
        Mockito.when(userService.login(any(BaseQuery.class), any(), any(), isNull()))
            .thenReturn(okVo());
        mvc.perform(post("/api/game/v1/login")
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"name\":\"a b\",\"pwd\":\"p@ss\"}"))
            .andExpect(status().isOk());

        ArgumentCaptor<String> name = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> pwd = ArgumentCaptor.forClass(String.class);
        Mockito.verify(userService).login(any(BaseQuery.class), name.capture(), pwd.capture(), isNull());
        assertEquals("a b", name.getValue());
        assertEquals("p@ss", pwd.getValue());
    }
}
