package com.timeline.vpn.photosolve;

import com.timeline.vpn.exception.ApiException;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.po.UserPo;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.photosolve.model.PhotoSolveErrno;
import com.timeline.vpn.photosolve.model.PhotoSolveResponse;
import com.timeline.vpn.util.JsonUtil;
import com.timeline.vpn.web.common.resolver.UserInfo;
import com.timeline.vpn.web.controller.BaseController;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * 拍照解题接口。
 *
 * 路径带上版本：`/api/photosolve/v1/`。以后做破坏性变更时开 v2，v1 继续保持可用。
 *
 * | 接口 | 说明 |
 * |---|---|
 * | `POST /api/photosolve/v1/solve.json` | multipart，字段 `images`（可重复）+ `text`/`subject`/`grade`/`clientRequestId` |
 * | `GET  /api/photosolve/v1/health.json` | 部署自检：模型配置是否就绪（不需要登录） |
 *
 * 为什么不拆「先 upload 再 solve」两步：题目图是端上压缩后的一张（或几张）JPEG，5MB 以内，
 * 一次 multipart 就能传完；拆两步既多一次往返，又要在服务端保留临时文件。以后要做异步长任务
 * （比如整页多题、需要排队）时再加 `POST /solve` + `GET /result` 的异步版本。
 *
 * <h3>为什么必须登录</h3>
 * 每次调用都是一次付费的模型请求。不登录就无法按用户计额，也无法在滥用时定位到人——
 * 结果是任何人拿一个空 token 就能把账单打爆。所以 {@code @UserInfo(required = true)}，
 * 未登录直接由 {@link com.timeline.vpn.web.common.resolver.UserInfoResolver} 抛 token 过期。
 * `health.json` 不在此列：它是部署自检，不碰模型，也不该要求登录。
 */
@Slf4j
@RestController
@RequestMapping("/api/photosolve/v1")
public class PhotoSolveController extends BaseController {

    private final PhotoSolveProvider provider;
    private final PhotoSolveQuota quota;

    public PhotoSolveController(PhotoSolveProvider provider, PhotoSolveQuota quota) {
        this.provider = provider;
        this.quota = quota;
    }

    @PostMapping(value = "/solve.json", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public JsonResult solve(
            @UserInfo(required = true) BaseQuery baseQuery,
            @RequestParam(name = "images", required = false) MultipartFile[] images,
            @RequestParam(name = "text", required = false) String text,
            @RequestParam(name = "subject", required = false) String subject,
            @RequestParam(name = "grade", required = false) String grade,
            @RequestParam(name = "clientRequestId", required = false) String clientRequestId) {

        // 配置检查放在最前面：没配模型时直接返回 50002，不去读 5MB 请求体
        PhotoSolveConfig.requireConfigured();

        UserPo user = baseQuery.getUser();
        // required = true 时解析器已经保证非空；这里再判一次是为了防止有人改成 false 后忘记补
        if (user == null) {
            throw new ApiException(PhotoSolveErrno.BAD_REQUEST, "请先登录");
        }
        long userId = user.getId();

        String requestId = StringUtils.isBlank(clientRequestId)
                ? UUID.randomUUID().toString()
                : clientRequestId.trim();

        // 幂等：同一张图的上一次成功结果直接回放，既不重复调模型也不重复扣额度。
        // 这是客户端「重试」按钮最常命中的路径（网络超时但服务端其实已经算完了）。
        String cached = quota.cachedResult(userId, requestId);
        if (cached != null) {
            log.info("photosolve idempotent hit user={} requestId={}", userId, requestId);
            return new JsonResult(JsonUtil.readValue(cached, PhotoSolveResponse.class));
        }

        if (images == null || images.length == 0) {
            throw new ApiException(PhotoSolveErrno.BAD_REQUEST, "缺少图片");
        }
        int maxImages = PhotoSolveConfig.maxImages();
        if (images.length > maxImages) {
            throw new ApiException(PhotoSolveErrno.BAD_IMAGE, "最多上传 " + maxImages + " 张图片");
        }

        long maxBytes = PhotoSolveConfig.maxBytes();

        List<byte[]> payload = new ArrayList<>();
        List<String> mimes = new ArrayList<>();
        for (MultipartFile file : images) {
            if (file == null || file.isEmpty()) {
                continue;
            }
            if (file.getSize() > maxBytes) {
                throw new ApiException(PhotoSolveErrno.BAD_IMAGE,
                        "单张图片不能超过 " + (maxBytes / 1024 / 1024) + "MB");
            }
            String mime = resolveMime(file);
            if (mime == null) {
                throw new ApiException(PhotoSolveErrno.BAD_IMAGE, "只支持 JPEG/PNG/WebP 图片");
            }
            try {
                payload.add(file.getBytes());
                mimes.add(mime);
            } catch (IOException e) {
                log.error("photosolve {} failed to read upload", requestId, e);
                throw new ApiException(PhotoSolveErrno.BAD_IMAGE, PhotoSolveErrno.messageOf(PhotoSolveErrno.BAD_IMAGE));
            }
        }
        if (payload.isEmpty()) {
            throw new ApiException(PhotoSolveErrno.BAD_REQUEST, "缺少图片");
        }

        // 额度在调用模型之前占用：参数错误、图片过大都在上面拦掉了，不会白扣用户次数
        quota.acquire(userId, user.getLevel());

        log.info("photosolve {} images={} bytes={} subject={} user={}",
                requestId, payload.size(),
                payload.stream().mapToInt(b -> b.length).sum(),
                subject, user.getName());

        PhotoSolveResponse response;
        try {
            response = provider.solve(payload, mimes, text, subject, grade, requestId);
        } catch (ApiException e) {
            // 超时/模型不可用：用户什么都没拿到，退还额度。其它错误（40001/40002）钱已经花了，不退
            if (e.getStatus() == PhotoSolveErrno.MODEL_FAILED) {
                quota.refund(userId);
            }
            throw e;
        } catch (RuntimeException e) {
            // provider 之外的意外异常（SDK 抛的 NPE 等）：同样没给出结果，退还
            quota.refund(userId);
            log.error("photosolve {} unexpected provider failure", requestId, e);
            throw new ApiException(PhotoSolveErrno.MODEL_FAILED, PhotoSolveErrno.messageOf(PhotoSolveErrno.MODEL_FAILED));
        }

        // 模型判断「不是题目」时用错误码表达，客户端按 40002 处理比读 questionFound 更统一
        if (!response.isQuestionFound()) {
            throw new ApiException(PhotoSolveErrno.NOT_A_QUESTION,
                    PhotoSolveErrno.messageOf(PhotoSolveErrno.NOT_A_QUESTION));
        }

        // 只缓存成功结果。缓存失败不影响本次响应
        quota.cacheResult(userId, requestId, JsonUtil.writeValueAsString(response));
        return new JsonResult(response);
    }

    /**
     * 今日额度：客户端在首页展示「今日剩余 N 次」，用完时提前置灰拍照按钮，
     * 而不是让用户拍完、裁完、等上传完才看到 42901。
     */
    @PostMapping(value = "/quota.json")
    public JsonResult quota(@UserInfo(required = true) BaseQuery baseQuery) {
        UserPo user = baseQuery.getUser();
        if (user == null) {
            throw new ApiException(PhotoSolveErrno.BAD_REQUEST, "请先登录");
        }
        int limit = PhotoSolveQuota.dailyLimit(user.getLevel());
        long used = quota.usedToday(user.getId());
        java.util.Map<String, Object> data = new java.util.LinkedHashMap<>();
        data.put("limit", limit);
        data.put("used", used);
        data.put("remaining", Math.max(0L, limit - used));
        return new JsonResult(data);
    }

    /**
     * 部署自检：`curl -F` 之前先确认密钥、模型名读到了。
     * 只返回布尔值，不泄露任何密钥内容。
     */
    @PostMapping(value = "/health.json")
    public JsonResult health() {
        java.util.Map<String, Object> data = new java.util.LinkedHashMap<>();
        data.put("provider", provider.name());
        data.put("configured", provider.isAvailable());
        data.put("maxImages", PhotoSolveConfig.maxImages());
        data.put("maxBytes", PhotoSolveConfig.maxBytes());
        data.put("timeoutSeconds", PhotoSolveConfig.timeoutSeconds());
        return new JsonResult(data);
    }

    /** 从 Content-Type 或文件名判断 mime；不认识的返回 null。 */
    private static String resolveMime(MultipartFile file) {
        String contentType = file.getContentType();
        if (contentType != null) {
            String lower = contentType.toLowerCase();
            if (lower.startsWith("image/jpeg") || lower.startsWith("image/jpg")) {
                return "image/jpeg";
            }
            if (lower.startsWith("image/png")) {
                return "image/png";
            }
            if (lower.startsWith("image/webp")) {
                return "image/webp";
            }
        }
        String name = file.getOriginalFilename();
        if (name != null) {
            String lower = name.toLowerCase();
            if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) {
                return "image/jpeg";
            }
            if (lower.endsWith(".png")) {
                return "image/png";
            }
            if (lower.endsWith(".webp")) {
                return "image/webp";
            }
        }
        return null;
    }
}
