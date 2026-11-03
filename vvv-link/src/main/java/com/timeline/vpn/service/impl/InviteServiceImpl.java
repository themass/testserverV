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

@Service
public class InviteServiceImpl implements InviteService {

    private static final Logger LOGGER = LoggerFactory.getLogger(InviteServiceImpl.class);

    /** 邀请码字母表去掉了 0/O、1/I/L，避免口头或截图时看错。 */
    private static final String ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
    private static final int CODE_LENGTH = 8;
    /** 每次邀请各发放的观看券张数。 */
    static final int INVITE_TICKETS = 1;

    private final SecureRandom random = new SecureRandom();

    @Autowired
    private UserInviteDao inviteDao;
    @Autowired
    private RewardTicketDao ticketDao;

    @Override
    public String getOrCreateCode(String name) {
        String code = inviteDao.findCode(name);
        if (code != null) {
            return code;
        }
        // 碰撞概率很低；insert ignore 失败时重新查一次，拿到最终写入的那个码
        inviteDao.insert(name, newCode(), new Date());
        return inviteDao.findCode(name);
    }

    @Override
    public void applyInvite(String code, String invitee) {
        if (code == null || code.trim().isEmpty()) {
            return;
        }
        String inviter = inviteDao.findUserByCode(code.trim().toUpperCase());
        if (inviter == null) {
            LOGGER.info("邀请码无效: " + code + " invitee=" + invitee);
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

    private String newCode() {
        StringBuilder sb = new StringBuilder(CODE_LENGTH);
        for (int i = 0; i < CODE_LENGTH; i++) {
            sb.append(ALPHABET.charAt(random.nextInt(ALPHABET.length())));
        }
        return sb.toString();
    }
}
