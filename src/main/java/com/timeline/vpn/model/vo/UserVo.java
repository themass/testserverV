package com.timeline.vpn.model.vo;

import java.util.Date;

/**
 * @author gqli
 * @date 2016年3月10日 上午10:30:47
 * @version V1.0
 */
public class UserVo {
    private String name;
    private String sex;
    private int level;
    private String photo;
    private String token;
    private long score;
    private StateUseVo stateUse;
    private String email;
    private String areaMi;
    private Date paidStartTime;
    private Date paidEndTime;
    public String getAreaMi() {
        return areaMi;
    }

    public void setAreaMi(String areaMi) {
        this.areaMi = areaMi;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getSex() {
        return sex;
    }

    public void setSex(String sex) {
        this.sex = sex;
    }

    public int getLevel() {
        return level;
    }

    public void setLevel(int level) {
        this.level = level;
    }

    public String getPhoto() {
        return photo;
    }

    public void setPhoto(String photo) {
        this.photo = photo;
    }

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }

    public long getScore() {
        return score;
    }

    public void setScore(long score) {
        this.score = score;
    }

    public StateUseVo getStateUse() {
        return stateUse;
    }

    public void setStateUse(StateUseVo stateUse) {
        this.stateUse = stateUse;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public Date getPaidStartTime() {
        return paidStartTime;
    }

    public void setPaidStartTime(Date paidStartTime) {
        this.paidStartTime = paidStartTime;
    }

    public Date getPaidEndTime() {
        return paidEndTime;
    }

    public void setPaidEndTime(Date paidEndTime) {
        this.paidEndTime = paidEndTime;
    }


}

