package com.timeline.vpn.model.vo;

/** 当前用户的邀请码。 */
public class InviteVo {
    /** 邀请码（8 位大写字母与数字） */
    public String code;

    public InviteVo() {
    }

    public InviteVo(String code) {
        this.code = code;
    }
}
