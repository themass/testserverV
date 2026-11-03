package com.timeline.vpn.service.impl;

import com.timeline.vpn.Constant;
import com.timeline.vpn.dao.db.RewardTicketDao;
import com.timeline.vpn.dao.db.UserDao;
import com.timeline.vpn.exception.DataException;
import com.timeline.vpn.model.po.UserPo;
import com.timeline.vpn.model.vo.RewardStatusVo;
import com.timeline.vpn.service.RewardService;
import com.timeline.vpn.util.AdmobSsvVerifier;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.TimeZone;
import java.util.UUID;

@Service
public class RewardServiceImpl implements RewardService {

    /** 每天最多发放的观看券 */
    static final int DAILY_LIMIT = 10;
    /** 两次观看的冷却时间 */
    static final long COOLDOWN_MS = 60_000L;
    /** 观看券有效期 */
    static final long TICKET_TTL_MS = 7L * 24 * 3600 * 1000;
    /** 兑换：券数 与 VIP 小时数 */
    static final int REDEEM_TICKETS = 3;
    static final int REDEEM_HOURS = 2;
    /** 旧积分：每 30 分折算一张券 */
    static final long LEGACY_SCORE_PER_TICKET = 30;
    /** 单次折算上限，防止一次请求写入过多记录 */
    private static final int LEGACY_CONVERT_LIMIT = 100;

    private static final TimeZone ZONE = TimeZone.getTimeZone("Asia/Shanghai");

    @Autowired
    private RewardTicketDao ticketDao;
    @Autowired
    private UserDao userDao;

    @Override
    public boolean onAdmobCallback(String rawQuery) {
        if (!AdmobSsvVerifier.verify(rawQuery)) {
            return false;
        }
        Map<String, String> params = AdmobSsvVerifier.parseParams(rawQuery);
        String userName = params.get("user_id");
        String tx = params.get("transaction_id");
        if (userName == null || tx == null) {
            return true;
        }
        if (userDao.exist(userName) == null) {
            return true;
        }
        Date now = new Date();
        boolean allowed = ticketDao.countGrantedSince(userName, startOfToday()) < DAILY_LIMIT
                && cooldownPassed(userName, now);
        ticketDao.insert(userName, tx, allowed ? 1 : 0, now, new Date(now.getTime() + TICKET_TTL_MS));
        return true;
    }

    @Override
    @Transactional
    public RewardStatusVo status(String name) {
        convertLegacyScore(name);
        return build(name);
    }

    @Override
    @Transactional
    public RewardStatusVo redeem(String name) {
        Date now = new Date();
        List<Long> ids = ticketDao.lockAvailable(name, now, REDEEM_TICKETS);
        if (ids.size() < REDEEM_TICKETS) {
            throw new DataException(Constant.ResultMsg.RESULT_REWARD_NOT_ENOUGH);
        }
        ticketDao.markUsed(ids);
        UserPo po = userDao.exist(name);
        Date base = po.getPaidEndTime() != null && po.getPaidEndTime().after(now) ? po.getPaidEndTime() : now;
        Date end = new Date(base.getTime() + REDEEM_HOURS * 3600_000L);
        userDao.updateVip(name, Math.max(po.getLevel(), Constant.UserLevel.LEVEL_VIP), end);
        return build(name);
    }

    private boolean cooldownPassed(String userName, Date now) {
        Date last = ticketDao.lastGrantedAt(userName);
        return last == null || now.getTime() - last.getTime() >= COOLDOWN_MS;
    }

    /** 旧版积分折算：扣除积分并写入等量观看券。 */
    private void convertLegacyScore(String name) {
        UserPo po = userDao.exist(name);
        if (po == null || po.getScore() < LEGACY_SCORE_PER_TICKET) {
            return;
        }
        long tickets = Math.min(po.getScore() / LEGACY_SCORE_PER_TICKET, LEGACY_CONVERT_LIMIT);
        if (userDao.deductScore(name, tickets * LEGACY_SCORE_PER_TICKET) != 1) {
            return;
        }
        Date now = new Date();
        for (long i = 0; i < tickets; i++) {
            ticketDao.insert(name, "legacy-" + name + "-" + UUID.randomUUID(), 1, now,
                    new Date(now.getTime() + TICKET_TTL_MS));
        }
    }

    private RewardStatusVo build(String name) {
        Date now = new Date();
        RewardStatusVo vo = new RewardStatusVo();
        vo.tickets = ticketDao.countAvailable(name, now);
        vo.todayCount = ticketDao.countGrantedSince(name, startOfToday());
        vo.dailyLimit = DAILY_LIMIT;
        vo.cooldownSec = (int) (COOLDOWN_MS / 1000);
        vo.redeemTickets = REDEEM_TICKETS;
        vo.redeemHours = REDEEM_HOURS;
        vo.expiringTickets = ticketDao.countExpiringBefore(name, now, new Date(now.getTime() + 24L * 3600_000L));
        UserPo po = userDao.exist(name);
        if (po != null && po.getPaidEndTime() != null && po.getPaidEndTime().after(now)) {
            SimpleDateFormat fmt = new SimpleDateFormat("yyyy-MM-dd HH:mm");
            fmt.setTimeZone(ZONE);
            vo.vipEnd = fmt.format(po.getPaidEndTime());
        }
        return vo;
    }

    private static Date startOfToday() {
        Calendar cal = Calendar.getInstance(ZONE);
        cal.set(Calendar.HOUR_OF_DAY, 0);
        cal.set(Calendar.MINUTE, 0);
        cal.set(Calendar.SECOND, 0);
        cal.set(Calendar.MILLISECOND, 0);
        return cal.getTime();
    }
}
