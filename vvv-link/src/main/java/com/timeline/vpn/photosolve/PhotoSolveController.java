package com.timeline.vpn.photosolve;

import com.timeline.vpn.exception.ApiException;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.photosolve.model.PhotoSolveErrno;
import com.timeline.vpn.photosolve.model.PhotoSolveResponse;
import com.timeline.vpn.web.common.resolver.UserInfo;
import com.timeline.vpn.web.controller.BaseController;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.ModelAttribute;
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
 */
@Slf4j
@RestController
@RequestMapping("/api/photosolve/v1")
public class PhotoSolveController extends BaseController {

    private final PhotoSolveProvider provider;

    public PhotoSolveController(PhotoSolveProvider provider) {
        this.provider = provider;
    }

    @PostMapping(value = "/solve.json", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public JsonResult solve(
            @UserInfo BaseQuery baseQuery,
            @RequestParam(name = "images", required = false) MultipartFile[] images,
            @RequestParam(name = "text", required = false) String text,
            @RequestParam(name = "subject", required = false) String subject,
            @RequestParam(name = "grade", required = false) String grade,
            @RequestParam(name = "clientRequestId", required = false) String clientRequestId) {

        // 配置检查放在最前面：没配模型时直接返回 50002，不去读 5MB 请求体
        PhotoSolveConfig.requireConfigured();

        if (images == null || images.length == 0) {
            throw new ApiException(PhotoSolveErrno.BAD_REQUEST, "缺少图片");
        }
        int maxImages = PhotoSolveConfig.maxImages();
        if (images.length > maxImages) {
            throw new ApiException(PhotoSolveErrno.BAD_IMAGE, "最多上传 " + maxImages + " 张图片");
        }

        String requestId = StringUtils.isBlank(clientRequestId)
                ? UUID.randomUUID().toString()
                : clientRequestId.trim();
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

        log.info("photosolve {} images={} bytes={} subject={} user={}",
                requestId, payload.size(),
                payload.stream().mapToInt(b -> b.length).sum(),
                subject,
                baseQuery.getUser() == null ? "-" : baseQuery.getUser().getName());

        PhotoSolveResponse response = provider.solve(payload, mimes, text, subject, grade, requestId);

        // 模型判断「不是题目」时用错误码表达，客户端按 40002 处理比读 questionFound 更统一
        if (!response.isQuestionFound()) {
            throw new ApiException(PhotoSolveErrno.NOT_A_QUESTION,
                    PhotoSolveErrno.messageOf(PhotoSolveErrno.NOT_A_QUESTION));
        }
        return new JsonResult(response);
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
