package com.timeline.vpn.service.impl;

import com.timeline.vpn.dao.db.RewardTicketDao;
import com.timeline.vpn.dao.db.UserInviteDao;
import com.timeline.vpn.service.InviteService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.util.Date;

/**
 * 邀请码规则：
 * <ul>
 *   <li>码是数字 + 字母，默认 4 位；一旦随机撞上 10 天内发出过的码，本次改用 6 位。</li>
 *   <li>每个码有效 5 天。用户的码过期后，再次获取会重新生成。</li>
 *   <li>一个码发出后 10 天内不会再发给别人。</li>
 * </ul>
 */
@Service
public class InviteServiceImpl implements InviteService {

    private static final Logger LOGGER = LoggerFactory.getLogger(InviteServiceImpl.class);

    /** 字母表去掉了 0/O、1/I/L，避免口头或截图时看错。 */
    private static final String ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
    private static final int SHORT_LENGTH = 4;
    private static final int LONG_LENGTH = 6;
    /** 6 位码也撞上时的重试次数。 */
    private static final int MAX_ATTEMPTS = 20;
    /** 码的有效期：5 天。 */
    static final long VALID_MS = 5L * 24 * 3600_000L;
    /** 码发出后不允许再次发出的时间：10 天。 */
    static final long REUSE_BLOCK_MS = 10L * 24 * 3600_000L;
    /** 每次邀请各发放的观看券张数。 */
    static final int INVITE_TICKETS = 1;

    private final SecureRandom random = new SecureRandom();

    @Autowired
    private UserInviteDao inviteDao;
    @Autowired
    private RewardTicketDao ticketDao;

    @Override
    public String getOrCreateCode(String name) {
        Date now = new Date();
        String code = inviteDao.findCode(name);
        Date createdAt = inviteDao.findCreatedAt(name);
        if (code != null && createdAt != null && createdAt.getTime() >= now.getTime() - VALID_MS) {
            return code;
        }
        return issueCode(name, now);
    }

    /** 生成并记录一个新码：先 4 位，撞上了就改 6 位。 */
    private String issueCode(String name, Date now) {
        Date reuseCutoff = new Date(now.getTime() - REUSE_BLOCK_MS);
        int length = SHORT_LENGTH;
        String code = null;
        for (int attempt = 0; attempt < MAX_ATTEMPTS && code == null; attempt++) {
            String candidate = newCode(length);
            inviteDao.deleteStaleHistory(candidate, reuseCutoff);
            if (inviteDao.insertHistory(candidate, name, now) > 0) {
                code = candidate;
            } else {
                // 10 天内重复了：之后都用 6 位
                length = LONG_LENGTH;
            }
        }
        if (code == null) {
            LOGGER.error("邀请码生成失败（重复过多）user=" + name);
            throw new IllegalStateException("邀请码生成失败，请稍后再试");
        }
        inviteDao.deleteOtherOwner(code, name);
        inviteDao.upsert(name, code, now);
        return code;
    }

    @Override
    public void applyInvite(String code, String invitee) {
        if (code == null || code.trim().isEmpty()) {
            return;
        }
        String normalized = code.trim().toUpperCase();
        Date validSince = new Date(System.currentTimeMillis() - VALID_MS);
        String inviter = inviteDao.findUserByCode(normalized, validSince);
        if (inviter == null) {
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
