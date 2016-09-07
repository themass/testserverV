package com.timeline.vpn.model.po;

import java.util.Date;

/**
 * @author gqli
 * @date 2016年8月9日 上午10:56:12
 * @version V1.0
 */
public class UserPo {
    private long id;
    private String devId;
    private String name;
    private String pwd;
    private Date time;
    private String sex;
    private int level;
    private int useCount;
    private String photo;
    private long score;

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

    public int getUseCount() {
        return useCount;
    }

    public UserPo setUseCount(int useCount) {
        this.useCount = useCount;
        return this;
    }

    public String getDevId() {
        return devId;
    }

    public UserPo setDevId(String devId) {
        this.devId = devId;
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



}

