package com.timeline.vpn.web.controller.api;

import com.timeline.vpn.Constant;
import com.timeline.vpn.model.form.DanmakuPostForm;
import com.timeline.vpn.model.po.UserPo;
import com.timeline.vpn.model.vo.TimelinePostVo;
import com.timeline.vpn.model.vo.TimelineResult;
import com.timeline.vpn.service.CacheService;
import com.timeline.vpn.service.DataDanmakuService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Collections;

/**
 * 通用弹幕（时间轴域）。路径与 app 端 HttpDanmakuSource 逐字对齐：
 *
 * <pre>
 * GET    {base}/{namespace}/{contentId}/{editionId}/comments?startMs=&amp;endMs=&amp;limit=&amp;cursor=
 * POST   {base}/{namespace}/{contentId}/{editionId}/comments          body {clientMessageId, atMs, text}
 * DELETE {base}/{namespace}/{contentId}/{editionId}/comments/{id}
 * </pre>
 *
 * <p>base 挂在 {@code https://api.ok123find.top/vvv/api}（nginx 的通用 /vvv/ 转发，剥掉 /vvv 前缀），
 * 这里映射成 {@code /api/timeline/v1}。返回信封是自定义的 {@link TimelineResult}，刻意不用 JsonResult
 * ——非测试环境 JsonResult 会 AES 加密 data，而且弹幕路径不带 .json，HostFilter 不生效时
 * DevAppContext 直接为 null。业务异常仍落到 CommonHandlerExceptionResolver（errno 11003，data 为
 * null 不加密），app 端按 errno!=0 + error 文案展示。
 *
 * <p>鉴权：拦截器只挂 {@code /**\/*.json}，所以 token 在这里自己解 ——
 * {@code Authorization: Bearer <token>}，token 与老接口同一个（登录时 putUser 发的那个），
 * 走 cacheService.getUser 换 UserPo。GET 不要求登录（公开时间轴可读），发/撤要求。
 *
 * @author gqli
 * @date 2026年11月22日
 * @version V1.0
 */
@RestController
@RequestMapping("/api/timeline/v1")
public class TimelineController {

    /** 单页上限：比 app 默认页(200)宽裕一点，再多是客户端的事（它按 nextCursor 翻页）。 */
    private static final int MAX_LIMIT = 500;
    /** 弹幕文本上限（码点），与 app 输入框口径一致；表列 varchar(300) 留足字节。 */
    private static final int MAX_TEXT_CODEPOINTS = 100;
    /** path 段与 clientMessageId 的长度上限，和建表列宽一致。 */
    private static final int MAX_SEGMENT_LEN = 128;
    /** path 段安全字符集：字母数字和 . _ : -；app 端会把不安全字符哈希成 hex，天然落在这个集合里。 */
    private static final String SEGMENT_PATTERN = "^[A-Za-z0-9][A-Za-z0-9._:-]*$";

    private final DataDanmakuService dataDanmakuService;
    private final CacheService cacheService;

    public TimelineController(DataDanmakuService dataDanmakuService, CacheService cacheService) {
        this.dataDanmakuService = dataDanmakuService;
        this.cacheService = cacheService;
    }

    @RequestMapping(value = "/{namespace}/{contentId}/{editionId}/comments",
            method = RequestMethod.GET)
    public TimelineResult window(@PathVariable("namespace") String namespace,
            @PathVariable("contentId") String contentId,
            @PathVariable("editionId") String editionId,
            @RequestParam(name = "startMs") Long startMs,
            @RequestParam(name = "endMs") Long endMs,
            @RequestParam(name = "limit", defaultValue = "200") Integer limit,
            @RequestParam(name = "cursor", required = false) String cursor) {
        String bad = checkSegments(namespace, contentId, editionId);
        if (bad != null) {
            return TimelineResult.fail(Constant.ResultErrno.ERRNO_PARAM, bad);
        }
        if (startMs == null || endMs == null || startMs < 0 || endMs <= startMs) {
            return TimelineResult.fail(Constant.ResultErrno.ERRNO_PARAM, "时间窗参数不合法");
        }
        int page = limit == null || limit <= 0 ? 200 : Math.min(limit, MAX_LIMIT);
        Long after = null;
        if (cursor != null && !cursor.isEmpty()) {
            try {
                after = Long.valueOf(cursor);
            } catch (NumberFormatException e) {
                return TimelineResult.fail(Constant.ResultErrno.ERRNO_PARAM, "cursor 不合法");
            }
        }
        return TimelineResult.ok(dataDanmakuService.getWindow(namespace, contentId, editionId,
                startMs, endMs, after, page));
    }

    @RequestMapping(value = "/{namespace}/{contentId}/{editionId}/comments",
            method = RequestMethod.POST)
    public TimelineResult post(HttpServletRequest request,
            @PathVariable("namespace") String namespace,
            @PathVariable("contentId") String contentId,
            @PathVariable("editionId") String editionId,
            @RequestBody(required = false) DanmakuPostForm form) {
        String bad = checkSegments(namespace, contentId, editionId);
        if (bad != null) {
            return TimelineResult.fail(Constant.ResultErrno.ERRNO_PARAM, bad);
        }
        UserPo user = resolveUser(request);
        if (user == null) {
            return TimelineResult.fail(Constant.ResultErrno.ERRNO_NEED_LOGIN, "请先登录后再发弹幕");
        }
        if (form == null || isBlank(form.getClientMessageId())
                || form.getClientMessageId().length() > MAX_SEGMENT_LEN) {
            return TimelineResult.fail(Constant.ResultErrno.ERRNO_PARAM, "clientMessageId 不合法");
        }
        String text = form.getText() == null ? "" : form.getText().trim();
        if (text.isEmpty() || text.codePointCount(0, text.length()) > MAX_TEXT_CODEPOINTS) {
            return TimelineResult.fail(Constant.ResultErrno.ERRNO_PARAM, "弹幕不能为空且不超过100字");
        }
        if (form.getAtMs() < 0) {
            return TimelineResult.fail(Constant.ResultErrno.ERRNO_PARAM, "atMs 不合法");
        }
        TimelinePostVo vo = dataDanmakuService.post(namespace, contentId, editionId,
                user.getId(), user.getName(), form.getClientMessageId(), form.getAtMs(), text);
        return TimelineResult.ok(vo);
    }

    @RequestMapping(value = "/{namespace}/{contentId}/{editionId}/comments/{id}",
            method = RequestMethod.DELETE)
    public TimelineResult retract(HttpServletRequest request,
            @PathVariable("namespace") String namespace,
            @PathVariable("contentId") String contentId,
            @PathVariable("editionId") String editionId,
            @PathVariable("id") String id) {
        String bad = checkSegments(namespace, contentId, editionId);
        if (bad != null) {
            return TimelineResult.fail(Constant.ResultErrno.ERRNO_PARAM, bad);
        }
        UserPo user = resolveUser(request);
        if (user == null) {
            return TimelineResult.fail(Constant.ResultErrno.ERRNO_NEED_LOGIN, "请先登录后再撤回");
        }
        long commentId;
        try {
            commentId = Long.parseLong(id);
        } catch (NumberFormatException e) {
            return TimelineResult.fail(Constant.ResultErrno.ERRNO_PARAM, "弹幕 id 不合法");
        }
        dataDanmakuService.retract(commentId, user.getId());
        // app 端 request() 要求 data 非 null 才算成功；撤回没有返回体，给个空对象占位
        return TimelineResult.ok(Collections.emptyMap());
    }

    /** Authorization: Bearer <token> → cacheService.getUser；token 缺失或过期返回 null。 */
    private UserPo resolveUser(HttpServletRequest request) {
        String header = request.getHeader("Authorization");
        if (header == null) {
            return null;
        }
        String token = header.trim();
        if (token.regionMatches(true, 0, "Bearer ", 0, 7)) {
            token = token.substring(7).trim();
        }
        if (token.isEmpty()) {
            return null;
        }
        return cacheService.getUser(token);
    }

    private String checkSegments(String namespace, String contentId, String editionId) {
        if (!isSegment(namespace) || !isSegment(editionId)) {
            return "namespace/editionId 不合法";
        }
        if (contentId == null || contentId.length() > MAX_SEGMENT_LEN || contentId.isEmpty()) {
            return "contentId 不合法";
        }
        // contentId 是客户端生成的稳定 key（可能带 : 等），放宽到安全字符集即可
        if (!contentId.matches(SEGMENT_PATTERN)) {
            return "contentId 含非法字符";
        }
        return null;
    }

    private boolean isSegment(String value) {
        return value != null && !value.isEmpty() && value.length() <= 32
                && value.matches(SEGMENT_PATTERN);
    }

    private static boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
