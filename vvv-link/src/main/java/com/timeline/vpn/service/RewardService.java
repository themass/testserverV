package com.timeline.vpn.service;

import com.timeline.vpn.model.vo.RewardStatusVo;

public interface RewardService {

    /**
     * 处理 AdMob 服务端回调。签名无效返回 false（调用方应返回 403）。
     * 签名有效但不发放（超上限、冷却中、用户不存在）时仍返回 true，并记录审计数据。
     */
    boolean onAdmobCallback(String rawQuery);

    /** 查询观看券状态；同时把旧版积分（每 30 分一张券）折算成观看券。 */
    RewardStatusVo status(String name);

    /** 用 3 张观看券兑换 2 小时 VIP。券不足时抛出 DataException。 */
    RewardStatusVo redeem(String name);
}
