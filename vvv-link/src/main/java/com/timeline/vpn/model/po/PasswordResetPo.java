package com.timeline.vpn.model.po;

import java.util.Date;

/** 找回密码验证码记录（表 vpn.user_reset_code）。 */
public class PasswordResetPo {
    private long id;
    private String userName;
    private String codeHash;
    private Date expireAt;
    private int used;
    private int attempts;

    public long getId() { return id; }
    public void setId(long id) { this.id = id; }
    public String getUserName() { return userName; }
    public void setUserName(String userName) { this.userName = userName; }
    public String getCodeHash() { return codeHash; }
    public void setCodeHash(String codeHash) { this.codeHash = codeHash; }
    public Date getExpireAt() { return expireAt; }
    public void setExpireAt(Date expireAt) { this.expireAt = expireAt; }
    public int getUsed() { return used; }
    public void setUsed(int used) { this.used = used; }
    public int getAttempts() { return attempts; }
    public void setAttempts(int attempts) { this.attempts = attempts; }
}
