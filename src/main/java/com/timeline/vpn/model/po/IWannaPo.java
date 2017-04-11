package com.timeline.vpn.model.po;

import java.util.Date;

/**
 * @author gqli
 * @date 2016年9月7日 下午8:35:52
 * @version V1.0
 */
public class IWannaPo {
    private long id;
    private String name;
    private int likes;
    private String likeUsers;
    private Date createTime;
    private String content;
    private boolean finished;

    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getLikes() {
        return likes;
    }

    public void setLikes(int likes) {
        this.likes = likes;
    }

    public String getLikeUsers() {
        return likeUsers;
    }

    public void setLikeUsers(String likeUsers) {
        this.likeUsers = likeUsers;
    }

    public Date getCreateTime() {
        return createTime;
    }

    public void setCreateTime(Date createTime) {
        this.createTime = createTime;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public boolean isFinished() {
        return finished;
    }

    public void setFinished(boolean finished) {
        this.finished = finished;
    }


}

