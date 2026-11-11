package com.timeline.vpn.photosolve;

import com.timeline.vpn.Constant;
import com.timeline.vpn.exception.ApiException;
import com.timeline.vpn.photosolve.model.PhotoSolveErrno;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

/**
 * 拍照解题的用量控制。豆包按 token 计费，不做限制的话一个登录用户就能把账单打爆。
 *
 * <h3>四道闸，从外到内</h3>
 * <table>
 *   <tr><th>闸</th><th>键</th><th>默认值</th><th>目的</th></tr>
 *   <tr><td>幂等</td><td>{@code photosolve:idem:{userId}:{hash}}</td><td>10 分钟</td>
 *       <td>同一张图重试不重复调模型、不重复扣额度</td></tr>
 *   <tr><td>分钟限流</td><td>{@code photosolve:rl:m:{yyyyMMdd}:{userId}:{minute}</td><td>3 次/分</td>
 *       <td>挡住脚本刷；正常用户一分钟不会问三道题以上</td></tr>
 *   <tr><td>用户日额度</td><td>{@code photosolve:quota:d:{yyyyMMdd}:{userId}</td><td>免费 10 / VIP 50</td>
 *       <td>单个账号的成本上限</td></tr>
 *   <tr><td>全局日预算</td><td>{@code photosolve:budget:d:{yyyyMMdd}</td><td>2000 次</td>
 *       <td>熔断：即使被批量注册刷，单日账单也有硬上限</td></tr>
 * </table>
 *
 * <h3>扣费时机</h3>
 * 在**调用模型之前**占用额度。模型超时（50001）时退还，因为用户什么都没拿到；
 * 其它模型错误（比如 40002 不是题目）不退，钱已经花了。
 *
 * <h3>Redis 不可用时</h3>
 * 放行并打 WARN，而不是拒绝。原因：本项目所有登录态都存 Redis（{@code CacheServiceImpl}），
 * Redis 挂了本来就没人能登录；这里再抛「额度用完」只会误导用户。代价是 Redis 故障期间额度失效，
 * 需要靠日志里的 WARN 告警。
 *
 * <h3>为什么不用 {@code @Idempotent} 注解</h3>
 * {@code vvv-common} 里只有注解定义，没有对应的切面实现，放了也不会生效。这里手写更直白。
 */
@Slf4j
@Component
public class PhotoSolveQuota {

    private static final DateTimeFormatter DAY = DateTimeFormatter.ofPattern("yyyyMMdd");

    private static final String IDEM_KEY = "photosolve:idem:";
    private static final String MINUTE_KEY = "photosolve:rl:m:";
    private static final String DAILY_KEY = "photosolve:quota:d:";
    private static final String BUDGET_KEY = "photosolve:budget:d:";

    /** 计数键多留一天：跨零点时还能查到昨天的值，排查用。 */
    private static final Duration COUNTER_TTL = Duration.ofDays(2);

    private final StringRedisTemplate redis;

    public PhotoSolveQuota(StringRedisTemplate redis) {
        this.redis = redis;
    }

    // ------------------------------------------------------------------
    // 幂等
    // ------------------------------------------------------------------

    /** 上次成功结果的 JSON；没有命中返回 null（不区分「从没请求过」和「已过期」）。 */
    public String cachedResult(long userId, String clientRequestId) {
        if (!hasText(clientRequestId)) {
            return null;
        }
        try {
            return redis.opsForValue().get(idemKey(userId, clientRequestId));
        } catch (Exception e) {
            log.warn("photosolve idempotency lookup failed user={} key={}", userId, clientRequestId, e);
            return null;
        }
    }

    /** 缓存成功结果。只缓存成功：失败要让用户能重试。 */
    public void cacheResult(long userId, String clientRequestId, String json) {
        if (!hasText(clientRequestId) || !hasText(json)) {
            return;
        }
        int seconds = PhotoSolveConfig.quota().idempotentSeconds();
        if (seconds <= 0) {
            return;
        }
        try {
            redis.opsForValue().set(idemKey(userId, clientRequestId), json, Duration.ofSeconds(seconds));
        } catch (Exception e) {
            log.warn("photosolve idempotency store failed user={} key={}", userId, clientRequestId, e);
        }
    }

    // ------------------------------------------------------------------
    // 额度
    // ------------------------------------------------------------------

    /**
     * 占用一次额度。超限时抛 {@link ApiException}（42901 / 42902），调用方不需要再判断。
     *
     * @param userLevel {@link Constant.UserLevel}，>= LEVEL_VIP 走 VIP 额度
     */
    public void acquire(long userId, int userLevel) {
        PhotoSolveConfig.Quota q = PhotoSolveConfig.quota();
        String day = LocalDate.now().format(DAY);
        try {
            // 1) 分钟窗口：先挡掉脚本，这一步不计入日额度
            String minuteKey = MINUTE_KEY + day + ":" + userId + ":" + (System.currentTimeMillis() / 60_000L);
            long perMinute = incr(minuteKey, Duration.ofMinutes(2));
            if (perMinute > q.perMinute()) {
                log.warn("photosolve rate limited user={} perMinute={}", userId, perMinute);
                throw new ApiException(PhotoSolveErrno.QUOTA_EXCEEDED, "请求过于频繁，请稍后再试");
            }

            // 2) 用户日额度
            String dailyKey = DAILY_KEY + day + ":" + userId;
            long used = incr(dailyKey, COUNTER_TTL);
            int limit = dailyLimit(userLevel);
            if (used > limit) {
                redis.opsForValue().decrement(dailyKey);
                log.info("photosolve daily quota exhausted user={} used={} limit={}", userId, used, limit);
                throw new ApiException(PhotoSolveErrno.QUOTA_EXCEEDED,
                        "今日识别额度已用完（每天 " + limit + " 次），明天再来");
            }

            // 3) 全局日预算：即使被批量注册刷，单日总量也有上限
            String budgetKey = BUDGET_KEY + day;
            long total = incr(budgetKey, COUNTER_TTL);
            if (total > q.totalPerDay()) {
                redis.opsForValue().decrement(budgetKey);
                redis.opsForValue().decrement(dailyKey);   // 没走到模型，把用户这次退回去
                log.error("photosolve global budget exhausted total={} limit={}", total, q.totalPerDay());
                throw new ApiException(PhotoSolveErrno.BUDGET_EXHAUSTED,
                        PhotoSolveErrno.messageOf(PhotoSolveErrno.BUDGET_EXHAUSTED));
            }

            log.info("photosolve acquire user={} day={} dailyUsed={}/{} total={}/{}",
                    userId, day, used, limit, total, q.totalPerDay());
        } catch (ApiException e) {
            throw e;
        } catch (Exception e) {
            // Redis 故障：放行，靠 WARN 告警（见类注释）
            log.warn("photosolve quota check failed, allowing request user={}", userId, e);
        }
    }

    /**
     * 退还一次额度：只在「模型超时/失败、用户什么都没拿到」时调用。
     *
     * 幂等缓存不删，因为失败路径本来就没写缓存。
     */
    public void refund(long userId) {
        String day = LocalDate.now().format(DAY);
        try {
            Long daily = redis.opsForValue().decrement(DAILY_KEY + day + ":" + userId);
            if (daily != null && daily < 0) {
                // 已经退过头了（重复退款），归零
                redis.opsForValue().set(DAILY_KEY + day + ":" + userId, "0");
            }
            Long total = redis.opsForValue().decrement(BUDGET_KEY + day);
            if (total != null && total < 0) {
                redis.opsForValue().set(BUDGET_KEY + day, "0");
            }
            log.info("photosolve refund user={} day={}", userId, day);
        } catch (Exception e) {
            log.warn("photosolve refund failed user={}", userId, e);
        }
    }

    // ------------------------------------------------------------------

    /** 今天已用次数（给 quota.json 展示「今日剩余」用）。Redis 不可用时返回 0。 */
    public long usedToday(long userId) {
        String day = LocalDate.now().format(DAY);
        try {
            String raw = redis.opsForValue().get(DAILY_KEY + day + ":" + userId);
            return raw == null ? 0L : Math.max(0L, Long.parseLong(raw));
        } catch (Exception e) {
            log.warn("photosolve usage lookup failed user={}", userId, e);
            return 0L;
        }
    }

    /** 这个等级每天的额度。 */
    public static int dailyLimit(int userLevel) {
        PhotoSolveConfig.Quota q = PhotoSolveConfig.quota();
        return userLevel >= Constant.UserLevel.LEVEL_VIP ? q.vipPerDay() : q.freePerDay();
    }

    /** INCR 并保证有 TTL：Redis 的 INCR 不会带过期时间，第一次写入时补上。 */
    private long incr(String key, Duration ttl) {
        Long value = redis.opsForValue().increment(key);
        if (value == null) {
            return 0L;
        }
        if (value == 1L) {
            redis.expire(key, ttl);
        }
        return value;
    }

    private static String idemKey(long userId, String clientRequestId) {
        return IDEM_KEY + userId + ":" + clientRequestId;
    }

    private static boolean hasText(String s) {
        return s != null && !s.trim().isEmpty();
    }
}
