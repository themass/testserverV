package com.timeline.vpn.photosolve;

import com.timeline.vpn.exception.ApiException;
import com.timeline.vpn.photosolve.model.PhotoSolveErrno;
import com.timeline.vpn.util.Secrets;

/**
 * 拍照解题的配置项。全部来自外部 secrets.properties（见 secrets.properties.example），
 * **不要把真实密钥写进代码或配置文件**。
 *
 * 需要在 secrets.properties 里填：
 * <pre>
 * photosolve.doubao.apiKey=      # 火山方舟 API Key
 * photosolve.doubao.model=       # 接入点 id（形如 ep-xxxxxxxx）或模型名
 * photosolve.doubao.endpoint=    # 默认 https://ark.cn-beijing.volces.com/api/v3/
 * photosolve.maxImages=          # 一次请求最多几张图，默认 4
 * photosolve.maxBytes=           # 单张图上限（字节），默认 5MB
 * photosolve.timeoutSeconds=     # 调模型的总超时，默认 60
 * photosolve.quota.freePerDay=   # 免费用户每天可用次数，默认 10
 * photosolve.quota.vipPerDay=    # VIP 每天可用次数，默认 50
 * photosolve.quota.perMinute=    # 每用户每分钟最多几次，默认 3
 * photosolve.quota.totalPerDay=  # 全站每天总预算（熔断），默认 2000
 * photosolve.quota.idempotentSeconds= # 同一 clientRequestId 的结果缓存多久，默认 600
 * </pre>
 *
 * 之所以用 {@link Secrets}（启动时读一次）而不是 {@code @Value}：
 * 本项目的密钥统一放在 jar 外的文件里，改密钥不需要重新打包，和现有 Doubao/Vision handler 一致。
 */
public final class PhotoSolveConfig {

    /** 默认的火山方舟 v3 接口地址。同一个域名下的接入点靠 model 区分。 */
    public static final String DEFAULT_ENDPOINT = "https://ark.cn-beijing.volces.com/api/v3/";

    /** apiKey 短于这个长度基本是没填完或填错（火山方舟的 key 是 36 位）。 */
    private static final int MIN_API_KEY_LENGTH = 20;

    /** 模板里的占位符，如 {@code ep-2024xxxx-xxxxx}、{@code your-model}、{@code TODO}。 */
    private static final java.util.regex.Pattern PLACEHOLDER =
            java.util.regex.Pattern.compile("xxxx|your|todo|changeme|placeholder", java.util.regex.Pattern.CASE_INSENSITIVE);

    /**
     * 这些模型/接入点是否就绪。没配置时接口返回 50002，而不是抛一堆空指针。
     *
     * 不能只判断非空：模板里 model 写的是 {@code ep-2024xxxx-xxxxx}，部署时忘了改，
     * 以前这里照样返回 true，{@code health.json} 报 {@code configured:true}，
     * 直到有人真的调模型才发现不可用。现在占位符和过短的 key 都按未配置处理。
     */
    public static boolean isConfigured() {
        String key = apiKey();
        String model = model();
        if (!hasText(key) || !hasText(model)) {
            return false;
        }
        return key.trim().length() >= MIN_API_KEY_LENGTH && !PLACEHOLDER.matcher(model).find();
    }

    public static String apiKey() {
        return Secrets.get("photosolve.doubao.apiKey");
    }

    public static String model() {
        String configured = Secrets.get("photosolve.doubao.model");
        return hasText(configured) ? configured : Secrets.get("doubao.photoModel");
    }

    public static String endpoint() {
        String configured = Secrets.get("photosolve.doubao.endpoint");
        return hasText(configured) ? configured : DEFAULT_ENDPOINT;
    }

    public static int maxImages() {
        return intOf("photosolve.maxImages", 4);
    }

    /** 单张图上限的下限：低于它多半是单位写错了（把 5 当成 5MB，实际是 5 字节）。 */
    private static final long MIN_MAX_BYTES = 64 * 1024;

    /**
     * 单张图上限，单位**字节**。
     *
     * 配成 5 时（本意 5MB）以前会让所有图片都被判超限，客户端看到「单张图片不能超过 0MB」。
     * 现在低于 64KB 的值视为配置错误，回退到默认 5MB 并打 WARN。
     */
    public static long maxBytes() {
        long configured = intOf("photosolve.maxBytes", 5 * 1024 * 1024);
        if (configured < MIN_MAX_BYTES) {
            org.slf4j.LoggerFactory.getLogger(PhotoSolveConfig.class).warn(
                    "photosolve.maxBytes={} 小于 {} 字节，疑似单位写错（单位是字节），已回退到默认 5MB",
                    configured, MIN_MAX_BYTES);
            return 5L * 1024 * 1024;
        }
        return configured;
    }

    public static int timeoutSeconds() {
        return intOf("photosolve.timeoutSeconds", 60);
    }

    /** 用量控制的配置。改额度不需要重新打包，重启即可。 */
    public static Quota quota() {
        return new Quota(
                intOf("photosolve.quota.freePerDay", 10),
                intOf("photosolve.quota.vipPerDay", 50),
                intOf("photosolve.quota.perMinute", 3),
                intOf("photosolve.quota.totalPerDay", 2000),
                intOf("photosolve.quota.idempotentSeconds", 600)
        );
    }

    /** 一组额度参数。值是快照：一次请求内不会变。 */
    public static final class Quota {
        private final int freePerDay;
        private final int vipPerDay;
        private final int perMinute;
        private final int totalPerDay;
        private final int idempotentSeconds;

        Quota(int freePerDay, int vipPerDay, int perMinute, int totalPerDay, int idempotentSeconds) {
            this.freePerDay = freePerDay;
            this.vipPerDay = vipPerDay;
            this.perMinute = perMinute;
            this.totalPerDay = totalPerDay;
            this.idempotentSeconds = idempotentSeconds;
        }

        public int freePerDay() {
            return freePerDay;
        }

        public int vipPerDay() {
            return vipPerDay;
        }

        public int perMinute() {
            return perMinute;
        }

        public int totalPerDay() {
            return totalPerDay;
        }

        public int idempotentSeconds() {
            return idempotentSeconds;
        }
    }

    /**
     * 检查配置，缺失时抛出对客户端有意义的错误码。
     * Controller 在收图之前调用，避免白白读一遍 5MB 的请求体。
     */
    public static void requireConfigured() {
        if (!isConfigured()) {
            throw new ApiException(PhotoSolveErrno.PROVIDER_NOT_CONFIGURED,
                    PhotoSolveErrno.messageOf(PhotoSolveErrno.PROVIDER_NOT_CONFIGURED));
        }
    }

    private static int intOf(String key, int fallback) {
        String raw = Secrets.get(key);
        if (!hasText(raw)) {
            return fallback;
        }
        try {
            return Integer.parseInt(raw.trim());
        } catch (NumberFormatException e) {
            return fallback;
        }
    }

    private static boolean hasText(String value) {
        return value != null && !value.trim().isEmpty();
    }

    private PhotoSolveConfig() {
    }
}
