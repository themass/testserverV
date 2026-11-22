package com.timeline.vpn.web.controller.api;

import com.timeline.vpn.Constant;
import com.timeline.vpn.exception.LoginException;
import com.timeline.vpn.model.form.UserRegForm;
import com.timeline.vpn.model.form.UserResetPwdForm;
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

    // ==================== /api/game/v1/register ====================

    /**
     * 注册成功：Form 字段原样透传给 userService.reg(form, baseQuery)，服务端补中性 sex，
     * BaseQuery.appInfo 复用 login 同一套手工构造（reg 里 updateDevUseinfo 要读它）。
     */
    @Test
    void registerSuccessBuildsFormWithNeutralSexAndReusesBaseQuery() throws Exception {
        mvc.perform(post("/api/game/v1/register")
                .contentType(MediaType.APPLICATION_JSON)
                .header("X-forwarded-for", "203.0.113.9")
                .content("{\"name\":\"tom\",\"pwd\":\"pwd123\",\"rePwd\":\"pwd123\","
                        + "\"email\":\"tom@example.com\"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.errno").value(0))
            .andExpect(jsonPath("$.data").doesNotExist());

        ArgumentCaptor<UserRegForm> form = ArgumentCaptor.forClass(UserRegForm.class);
        ArgumentCaptor<BaseQuery> query = ArgumentCaptor.forClass(BaseQuery.class);
        Mockito.verify(userService).reg(form.capture(), query.capture());

        assertEquals("tom", form.getValue().getName());
        assertEquals("pwd123", form.getValue().getPwd());
        assertEquals("pwd123", form.getValue().getRePwd());
        assertEquals("tom@example.com", form.getValue().getEmail());
        // sex 是 Form 必填但 H5 没有这个输入项：服务端固定填中性值 "0"
        assertEquals("0", form.getValue().getSex());

        DevApp app = query.getValue().getAppInfo();
        assertNotNull(app);
        assertEquals(Constant.VPN, app.getChannel());
        assertEquals("203.0.113.9", app.getUserIp());
        org.junit.jupiter.api.Assertions.assertTrue(app.getDevId().startsWith("web-"));
    }

    /** email 可选：不传就是 null（列本身 NULL），不影响注册。 */
    @Test
    void registerWithoutEmail() throws Exception {
        mvc.perform(post("/api/game/v1/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"tom\",\"pwd\":\"pwd123\",\"rePwd\":\"pwd123\"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.errno").value(0));

        ArgumentCaptor<UserRegForm> form = ArgumentCaptor.forClass(UserRegForm.class);
        Mockito.verify(userService).reg(form.capture(), any(BaseQuery.class));
        org.junit.jupiter.api.Assertions.assertNull(form.getValue().getEmail());
    }

    /** 用户名已存在：reg() 抛 RESULT.ERROR.EXIST → 11001 + 玩家能懂的中文，不透出 key。 */
    @Test
    void registerExistingNameMapsToChineseError() throws Exception {
        Mockito.doThrow(new LoginException(Constant.ResultMsg.RESULT_EXIST_ERROR))
            .when(userService).reg(any(UserRegForm.class), any(BaseQuery.class));

        mvc.perform(post("/api/game/v1/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"tom\",\"pwd\":\"pwd123\",\"rePwd\":\"pwd123\"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.errno").value(Constant.ResultErrno.ERRNO_PWD))
            .andExpect(jsonPath("$.error").value("用户名已存在"))
            .andExpect(jsonPath("$.data").doesNotExist());
    }

    /** 两次密码不一致：在门口拦下（reg() 的该分支语义是"垃圾用户"日志 + 21000，不该走到）。 */
    @Test
    void registerPwdMismatchRejectedWithoutTouchingService() throws Exception {
        mvc.perform(post("/api/game/v1/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"tom\",\"pwd\":\"pwd123\",\"rePwd\":\"other456\"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.errno").value(Constant.ResultErrno.ERRNO_PARAM))
            .andExpect(jsonPath("$.error").value("两次输入的密码不一致"));

        Mockito.verifyNoInteractions(userService);
    }

    /** 空参（缺 name / 缺 pwd / body 为空对象 / 无 body）：11002，不触达 UserService。 */
    @Test
    void registerBlankParamsRejectedWithoutTouchingService() throws Exception {
        mvc.perform(post("/api/game/v1/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"\",\"pwd\":\"x\",\"rePwd\":\"x\"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.errno").value(Constant.ResultErrno.ERRNO_PARAM))
            .andExpect(jsonPath("$.error").value("用户名和密码不能为空"));

        mvc.perform(post("/api/game/v1/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.errno").value(Constant.ResultErrno.ERRNO_PARAM));

        mvc.perform(post("/api/game/v1/register").contentType(MediaType.APPLICATION_JSON))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.errno").value(Constant.ResultErrno.ERRNO_PARAM));

        Mockito.verifyNoInteractions(userService);
    }

    /** reg() 抛未知 key：兜底 10000 + 通用文案，不透露细节。 */
    @Test
    void registerUnknownFailureMapsToSystemError() throws Exception {
        Mockito.doThrow(new IllegalStateException("db down"))
            .when(userService).reg(any(UserRegForm.class), any(BaseQuery.class));

        mvc.perform(post("/api/game/v1/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"tom\",\"pwd\":\"pwd123\",\"rePwd\":\"pwd123\"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.errno").value(Constant.ResultErrno.ERRNO_SYSTEM))
            .andExpect(jsonPath("$.error").value("注册失败，请稍后再试"));
    }

    // ==================== /api/game/v1/findpass ====================

    /** 发验证码成功：email 原样透传 requestPasswordReset，成功就是 errno 0 且不出文案。 */
    @Test
    void findPassSuccessPassesEmailThrough() throws Exception {
        mvc.perform(post("/api/game/v1/findpass")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"tom@example.com\"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.errno").value(0));

        Mockito.verify(userService).requestPasswordReset("tom@example.com");
    }

    /** SMTP 失败：service 抛 RESULT.ERROR.RESETMAIL → 中文"邮件发送失败，请稍后再试"。 */
    @Test
    void findPassMailFailureMapsToChineseError() throws Exception {
        Mockito.doThrow(new LoginException(Constant.ResultMsg.RESULT_RESET_MAIL_FAIL))
            .when(userService).requestPasswordReset("tom@example.com");

        mvc.perform(post("/api/game/v1/findpass")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"tom@example.com\"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.errno").value(Constant.ResultErrno.ERRNO_PWD))
            .andExpect(jsonPath("$.error").value("邮件发送失败，请稍后再试"));
    }

    /** 邮箱没绑定账号时 service 自己静默返回（不泄露存在性），这里同样回 errno 0——文案归前端。 */
    @Test
    void findPassUnknownEmailStaysSilentSuccess() throws Exception {
        Mockito.doNothing().when(userService).requestPasswordReset("ghost@example.com");

        mvc.perform(post("/api/game/v1/findpass")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"ghost@example.com\"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.errno").value(0))
            .andExpect(jsonPath("$.error").doesNotExist());
    }

    @Test
    void findPassBlankEmailRejectedWithoutTouchingService() throws Exception {
        mvc.perform(post("/api/game/v1/findpass")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"\"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.errno").value(Constant.ResultErrno.ERRNO_PARAM))
            .andExpect(jsonPath("$.error").value("邮箱不能为空"));

        mvc.perform(post("/api/game/v1/findpass").contentType(MediaType.APPLICATION_JSON))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.errno").value(Constant.ResultErrno.ERRNO_PARAM));

        Mockito.verifyNoInteractions(userService);
    }

    // ==================== /api/game/v1/resetpass ====================

    /** 重置成功：四个字段原样组装成 UserResetPwdForm，语义全在 service 内。 */
    @Test
    void resetPassSuccessBuildsForm() throws Exception {
        mvc.perform(post("/api/game/v1/resetpass")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"tom@example.com\",\"code\":\"123456\","
                        + "\"pwd\":\"newPwd123\",\"rePwd\":\"newPwd123\"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.errno").value(0));

        ArgumentCaptor<UserResetPwdForm> form = ArgumentCaptor.forClass(UserResetPwdForm.class);
        Mockito.verify(userService).resetPassword(form.capture());
        assertEquals("tom@example.com", form.getValue().getEmail());
        assertEquals("123456", form.getValue().getCode());
        assertEquals("newPwd123", form.getValue().getPwd());
        assertEquals("newPwd123", form.getValue().getRePwd());
    }

    /** 验证码过期/次数用尽（service 同一把 key）→ 11001 + "验证码已过期，请重新获取"。 */
    @Test
    void resetPassExpiredCodeMapsToChineseError() throws Exception {
        Mockito.doThrow(new LoginException(Constant.ResultMsg.RESULT_RESET_CODE_EXPIRED))
            .when(userService).resetPassword(any(UserResetPwdForm.class));

        mvc.perform(post("/api/game/v1/resetpass")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"tom@example.com\",\"code\":\"123456\","
                        + "\"pwd\":\"newPwd123\",\"rePwd\":\"newPwd123\"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.errno").value(Constant.ResultErrno.ERRNO_PWD))
            .andExpect(jsonPath("$.error").value("验证码已过期，请重新获取"));
    }

    /** 两次密码不一致（service 的 MISMATCH）→ 11002 + 中文，与注册口径同一句话。 */
    @Test
    void resetPassPwdMismatchMapsToChineseError() throws Exception {
        Mockito.doThrow(new LoginException(Constant.ResultMsg.RESULT_RESET_PWD_MISMATCH))
            .when(userService).resetPassword(any(UserResetPwdForm.class));

        mvc.perform(post("/api/game/v1/resetpass")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"tom@example.com\",\"code\":\"123456\","
                        + "\"pwd\":\"newPwd123\",\"rePwd\":\"other456\"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.errno").value(Constant.ResultErrno.ERRNO_PARAM))
            .andExpect(jsonPath("$.error").value("两次输入的密码不一致"));
    }

    /** 验证码错（RESULT.ERROR.RESETCODE）与未知异常都走兜底 10000，不透露"码是对是错"。 */
    @Test
    void resetPassUnknownFailureMapsToSystemError() throws Exception {
        Mockito.doThrow(new LoginException(Constant.ResultMsg.RESULT_RESET_CODE_ERROR))
            .when(userService).resetPassword(any(UserResetPwdForm.class));

        mvc.perform(post("/api/game/v1/resetpass")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"tom@example.com\",\"code\":\"000000\","
                        + "\"pwd\":\"newPwd123\",\"rePwd\":\"newPwd123\"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.errno").value(Constant.ResultErrno.ERRNO_SYSTEM))
            .andExpect(jsonPath("$.error").value("重置失败，请稍后再试"));
    }

    @Test
    void resetPassBlankParamsRejectedWithoutTouchingService() throws Exception {
        mvc.perform(post("/api/game/v1/resetpass")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"tom@example.com\",\"code\":\"\",\"pwd\":\"x\",\"rePwd\":\"x\"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.errno").value(Constant.ResultErrno.ERRNO_PARAM));

        mvc.perform(post("/api/game/v1/resetpass").contentType(MediaType.APPLICATION_JSON))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.errno").value(Constant.ResultErrno.ERRNO_PARAM));

        Mockito.verifyNoInteractions(userService);
    }
}
