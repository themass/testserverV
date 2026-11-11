package com.timeline.vpn.photosolve;

import com.timeline.vpn.photosolve.model.PhotoSolveResponse;

import java.util.List;

/**
 * 解题模型的统一接口。
 *
 * 现在只有豆包（火山方舟）一个实现；换模型（通义、DeepSeek、Gemini……）时新增一个
 * `@Component` 实现即可，Controller 和客户端都不变。选择哪个实现由 Spring 注入决定，
 * 以后要按配置切换，就在这里加一个 `PhotoSolveProviderResolver`。
 *
 * 实现约定：
 * - 输入是**已经过尺寸/格式校验**的 JPEG/PNG 字节，不需要再压缩；
 * - 只负责「调模型 + 解析结构化结果」，不负责错误码到 HTTP 的映射（由 Controller 处理）；
 * - 抛 {@link com.timeline.vpn.exception.ApiException} 表示可映射到客户端的业务错误。
 */
public interface PhotoSolveProvider {

    /** 实现名，写进响应的 providerUsed，便于排查。 */
    String name();

    /** 当前是否可用（密钥、模型名都配好了）。 */
    boolean isAvailable();

    /**
     * 解题。
     *
     * @param images    图片字节（JPEG/PNG），按用户上传顺序
     * @param text      用户补充的文字，可为 null
     * @param subject   学科提示，可为 null
     * @param grade     年级提示，可为 null
     * @param requestId 本次请求 id，仅用于日志
     */
    PhotoSolveResponse solve(List<byte[]> images, List<String> mimeTypes, String text,
                             String subject, String grade, String requestId);
}
