package com.timeline.vpn.model.vo;

/** 观看券状态（给客户端展示进度用）。 */
public class RewardStatusVo {
    /** 当前可用观看券数量 */
    public int tickets;
    /** 今日已发放数量 */
    public int todayCount;
    /** 每日上限 */
    public int dailyLimit;
    /** 两次观看的冷却秒数 */
    public int cooldownSec;
    /** 兑换所需观看券数 */
    public int redeemTickets;
    /** 每次兑换得到的 VIP 小时数 */
    public int redeemHours;
    /** VIP 到期时间（yyyy-MM-dd HH:mm，Asia/Shanghai），没有 VIP 时为空 */
    public String vipEnd;
    /** 24 小时内即将过期的观看券数量（客户端据此提醒用户及时使用） */
    public int expiringTickets;
}
