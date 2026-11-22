package com.timeline.vpn.web.controller.api;

import com.timeline.vpn.Constant;
import com.timeline.vpn.exception.ApiException;
import com.timeline.vpn.exception.LoginException;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.DevApp;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.model.vo.UserVo;
import com.timeline.vpn.service.UserService;
import com.timeline.vpn.util.Md5;
import com.timeline.vpn.util.UrlUtil;

import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 飞机对决 H5 页登录（POST /api/game/v1/login，上线加固 2026-11-22）。
 *
 * <p>与 /api/user/login.json 的差异只在"皮"：无 .json 后缀（WebConfig 拦截器只挂
 * /**&#47;*.json，故 UserCheck/Version/Cost/Blackdev 均不经过，HostFilter 的 url-pattern
 * 也是 *.json——这条路径完全不进 DevAppContext），JSON body 而非表单。业务语义完整复用
 * {@link UserService#login}：密码错误与账号不存在同为 RESULT.ERROR.PWD（不泄露存在性）、
 * 滥用黑名单、设备数上限、token 发放（cacheService.putUser，同库同键，TTL 1440 分钟）。
 *
 * <p>login() 要求 BaseQuery.getAppInfo() 非空（channel/devId/ua/userIp 都会走到），而这条
 * 路径没有 HostFilter 造 DevApp——这里参照 DeviceUtil.getAPPInfo 手工构造：channel=VVV、
 * platform=web、version 用可 Integer.valueOf 的合法值（UserCheck 的 isDog 分支会解析它）、
 * devId="web-"+md5(请求IP) 截 16 位（同浏览器会话复用设备行，不刷爆 devuseinfo）、
 * ua 透传真实 UA（updateDevUseinfo 对 ua 做 substring，绝不给 null）。
 *
 * <p>响应 data.token 是 cacheService.putUser 的原样返回（即 Redis 键 token_&lt;raw&gt; 全串，
 * 与 login.json 的 UserVo.token 同一口径，两个接口的 token 可互换）；游戏侧
 * GameTokenResolver 对带/不带 token_ 前缀两种形态都认。
 *
 * <p>错误文案按要求出中文（login.json 走 MessageSource 出英文，这里不透传 key）。
 */
@RestController
@RequestMapping("/api/game/v1")
public class GameLoginController {

    private static final Logger LOGGER = LoggerFactory.getLogger(GameLoginController.class);

    private final UserService userService;

    /** 单构造器：Spring 隐式注入（与测试直接 new 传假 Service 两用）。 */
    public GameLoginController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping("/login")
    public JsonResult login(HttpServletRequest request,
                            @RequestBody(required = false) Map<String, String> body) {
        String name = body == null ? null : body.get("name");
        String pwd = body == null ? null : body.get("pwd");
        if (!StringUtils.hasText(name) || !StringUtils.hasText(pwd)) {
            return new JsonResult(Constant.ResultErrno.ERRNO_PARAM, "用户名和密码不能为空");
        }
        try {
            UserVo vo = userService.login(buildBaseQuery(request), name, pwd, null);
            // 只回 token + name：areaMi(pwd 旧字段)/积分/设备明细一律不出网（H5 面最小暴露）
            Map<String, Object> data = new LinkedHashMap<>();
            data.put("token", vo.getToken());
            data.put("name", vo.getName());
            // getData() 的覆写是这条路径的必需品，两处：
            // ①基类 getData() 读 DevAppContext ThreadLocal——本路径不过 HostFilter（url-pattern
            //   是 *.json），ThreadLocal 为空，基类直接 NPE；
            // ②基类在非 test 环境把 data AES 加密成串——H5 是普通 fetch，契约要明文 JSON
            //   （apps/client auth.ts：body.data.token 直读）。
            // 错误响应 data==null，基类短路不读上下文，不需要覆写。
            return new JsonResult(data) {
                @Override public Object getData() { return data; }
            };
        } catch (LoginException e) {
            // 11001：密码错/账号不存在/黑名单/设备数超限——语义与 login.json 完全一致
            LOGGER.warn("game login failed: name={}, key={}", name, e.getMessage());
            return new JsonResult(e.getStatus(), zhError(e.getMessage()));
        } catch (ApiException e) {
            LOGGER.warn("game login failed: name={}, key={}", name, e.getMessage());
            return new JsonResult(e.getStatus(), "登录失败，请稍后再试");
        } catch (RuntimeException e) {
            LOGGER.error("game login error: name=" + name, e);
            return new JsonResult(Constant.ResultErrno.ERRNO_SYSTEM, "系统繁忙，请稍后再试");
        }
    }

    /** 中文错误文案（按 login() 实际会抛的三把 key 映射；未知 key 不透露细节）。 */
    private static String zhError(String key) {
        if (Constant.ResultMsg.RESULT_PWD_ERROR.equals(key)) return "用户名或密码错误";
        if (Constant.ResultMsg.RESULT_ERROR_USER.equals(key)) return "账号异常，请稍后再试";
        if (Constant.ResultMsg.RESULT_ERROR_MANYUSERLOG.equals(key)) return "登录设备过多，请稍后再试";
        return "登录失败，请稍后再试";
    }

    /** 手工构造 DevApp（口径见类注释；字段取全 login() 及 updateDevUseinfo 异步线程会读到的）。 */
    static BaseQuery buildBaseQuery(HttpServletRequest request) {
        String ip = UrlUtil.getIpAddr(request);
        if (ip == null) ip = "";
        String ua = request.getHeader(Constant.HTTP_UA);

        DevApp app = new DevApp();
        app.setDevId("web-" + Md5.encode("game-web|" + ip).substring(0, 16));
        app.setUserIp(ip);
        app.setChannel(Constant.VPN);          // 渠道归 VVV（login 内 SEX 前缀改写分支不涉及）
        app.setPlatform("web");
        app.setVersion("1000000000");          // 与 getAppVersion 产物同型、可 Integer.valueOf
        app.setVersionName("1.0.0.0");
        app.setUa(StringUtils.hasText(ua) ? ua : "web");  // updateDevUseinfo 对 ua 做 substring
        app.setTokenHeader(Constant.HTTP_TOKEN_KEY);
        app.setHost(request.getHeader("Host"));
        app.setTime(System.currentTimeMillis());

        BaseQuery query = new BaseQuery();
        query.setAppInfo(app);
        return query;
    }
}
