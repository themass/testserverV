package com.timeline.vpn.model.po;

import java.util.Date;

import com.timeline.vpn.util.DateTimeUtils;

/**
 * @author gqli
 * @date 2016年8月9日 上午10:56:12
 * @version V1.0
 */
public class UserPo {
    private long id;
    private String name;
    private String pwd;
    private Date time;
    private String sex;
    private int level;
    private String photo;
    private long score;
    private String email; 
    private Date paidStartTime;
    private Date paidEndTime;
    private String channel;
    public long getId() {
        return id;
    }

    public UserPo setId(long id) {
        this.id = id;
        return this;
    }

    public String getName() {
        return name;
    }

    public UserPo setName(String name) {
        this.name = name;
        return this;
    }

    public String getPwd() {
        return pwd;
    }

    public UserPo setPwd(String pwd) {
        this.pwd = pwd;
        return this;
    }

    public Date getTime() {
        return time;
    }

    public UserPo setTime(Date time) {
        this.time = time;
        return this;
    }

    public String getSex() {
        return sex;
    }

    public UserPo setSex(String sex) {
        this.sex = sex;
        return this;
    }

    public int getLevel() {
        return level;
    }

    public UserPo setLevel(int level) {
        this.level = level;
        return this;
    }
    public String getPhoto() {
        return photo;
    }

    public void setPhoto(String photo) {
        this.photo = photo;
    }

    public long getScore() {
        return score;
    }

    public void setScore(long score) {
        this.score = score;
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

    public String getChannel() {
      return channel;
    }

    public void setChannel(String channel) {
      this.channel = channel;
    }

    @Override
    public String toString() {
        return "UserPo [id=" + id + ", name=" + name + ", pwd=" + pwd + ", time=" + time + ", sex="
                + sex + ", level=" + level + ", photo=" + photo + ", score=" + score + ", email="
                + email + ", paidStartTime=" + DateTimeUtils.formatDate(paidStartTime) + ", paidEndTime=" + DateTimeUtils.formatDate(paidEndTime)
                + ", channel=" + channel + "]";
    }
    


}

