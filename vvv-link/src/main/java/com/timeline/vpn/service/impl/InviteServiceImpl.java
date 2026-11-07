package com.timeline.vpn.service.impl;

import com.timeline.vpn.dao.db.RewardTicketDao;
import com.timeline.vpn.service.InviteService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.Duration;
import java.util.Date;

/**
 * 邀请码规则（存在 Redis，不建表）：
 * <ul>
 *   <li>码是数字 + 字母，默认 4 位；一旦随机撞上 10 天内发出过的码，本次改用 6 位。</li>
 *   <li>每个码有效 5 天。用户的码过期后，再次获取会重新生成。</li>
 *   <li>一个码发出后 10 天内不会再发给别人。</li>
 * </ul>
 * 键：
 * <ul>
 *   <li>invite:code:&lt;码&gt; = 持有者用户名，TTL 10 天（用 SET NX 占用，存在即表示 10 天内已发出）</li>
 *   <li>invite:user:&lt;用户名&gt; = 当前邀请码，TTL 5 天（过期即失效）</li>
 * </ul>
 * Redis 重启或数据被淘汰时记录会丢，已发出的码可能在 10 天内被再次发出，这一点是可接受的取舍。
 */
@Service
public class InviteServiceImpl implements InviteService {

    private static final Logger LOGGER = LoggerFactory.getLogger(InviteServiceImpl.class);

    /** 字母表去掉了 0/O、1/I/L，避免口头或截图时看错。 */
    private static final String ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
    private static final int SHORT_LENGTH = 4;
    private static final int LONG_LENGTH = 6;
    /** 随机重试次数。 */
    private static final int MAX_ATTEMPTS = 20;
    /** 码的有效期：5 天。 */
    static final Duration VALID_FOR = Duration.ofDays(5);
    /** 码发出后不允许再次发出的时间：10 天。 */
    static final Duration REUSE_BLOCK_FOR = Duration.ofDays(10);
    private static final String CODE_KEY = "invite:code:";
    private static final String USER_KEY = "invite:user:";
    /** 每次邀请各发放的观看券张数。 */
    static final int INVITE_TICKETS = 1;

    private final SecureRandom random = new SecureRandom();

    @Autowired
    private StringRedisTemplate redis;
    @Autowired
    private RewardTicketDao ticketDao;

    @Override
    public String getOrCreateCode(String name) {
        String current = redis.opsForValue().get(USER_KEY + name);
        if (current != null) {
            return current;
        }
        return issueCode(name);
    }

    /** 生成并记录一个新码：先 4 位，撞上了就改 6 位。 */
    private String issueCode(String name) {
        int length = SHORT_LENGTH;
        for (int attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
            String candidate = newCode(length);
            // SET NX：10 天内已发出过就返回 false
            Boolean reserved = redis.opsForValue().setIfAbsent(CODE_KEY + candidate, name, REUSE_BLOCK_FOR);
            if (Boolean.TRUE.equals(reserved)) {
                redis.opsForValue().set(USER_KEY + name, candidate, VALID_FOR);
                return candidate;
            }
            // 重复了：之后都用 6 位
            length = LONG_LENGTH;
        }
        LOGGER.error("邀请码生成失败（重复过多）user=" + name);
        throw new IllegalStateException("邀请码生成失败，请稍后再试");
    }

    @Override
    public void applyInvite(String code, String invitee) {
        if (code == null || code.trim().isEmpty()) {
            return;
        }
        String normalized = code.trim().toUpperCase();
        String inviter = redis.opsForValue().get(CODE_KEY + normalized);
        if (inviter == null || !normalized.equals(redis.opsForValue().get(USER_KEY + inviter))) {
            LOGGER.info("邀请码无效或已过期: " + code + " invitee=" + invitee);
            return;
        }
        if (inviter.equals(invitee)) {
            return;
        }
        Date now = new Date();
        Date expire = new Date(now.getTime() + RewardServiceImpl.TICKET_TTL_MS);
        // transaction_id 按被邀请人区分，唯一约束保证同一个人只会被发一次
        for (int i = 0; i < INVITE_TICKETS; i++) {
            ticketDao.insert(invitee, "invite-in-" + invitee + "-" + i, 1, now, expire);
            ticketDao.insert(inviter, "invite-out-" + invitee + "-" + i, 1, now, expire);
        }
    }

    private String newCode(int length) {
        StringBuilder sb = new StringBuilder(length);
        for (int i = 0; i < length; i++) {
            sb.append(ALPHABET.charAt(random.nextInt(ALPHABET.length())));
        }
        return sb.toString();
    }
}
