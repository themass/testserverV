package com.timeline.vpn.service;

/** 邀请码：每个用户一个，被邀请人注册时填写即可双方各得 1 张观看券。 */
public interface InviteService {

    /** 取用户的邀请码，没有则生成一个。 */
    String getOrCreateCode(String name);

    /**
     * 新用户注册时调用。邀请码无效或填的是自己的码，直接忽略（不影响注册）。
     * 同一个被邀请人只会发放一次。
     */
    void applyInvite(String code, String invitee);
}
