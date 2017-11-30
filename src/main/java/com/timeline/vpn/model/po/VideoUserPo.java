package com.timeline.vpn.model.po;

import java.util.Date;

/**
 * @author gqli
 * @date 2017年8月15日 下午6:05:17
 * @version V1.0
 */
public class VideoUserPo {
    private Integer id;
    private String name;
    private String pic;
    private Date updateTime;
    private Float rate;
    private Integer showType; 
    private String userId;
    private Integer count;
    public Integer getId() {
        return id;
    }
    public void setId(Integer id) {
        this.id = id;
    }
    public String getName() {
        return name;
    }
    public void setName(String name) {
        this.name = name;
    }

    public String getPic() {
        return pic;
    }
    public void setPic(String pic) {
        this.pic = pic;
    }
    public Date getUpdateTime() {
        return updateTime;
    }
    public void setUpdateTime(Date updateTime) {
        this.updateTime = updateTime;
    }
    public Float getRate() {
        return rate;
    }
    public void setRate(Float rate) {
        this.rate = rate;
    }
    public Integer getShowType() {
        return showType;
    }
    public void setShowType(Integer showType) {
        this.showType = showType;
    }
    public String getUserId() {
        return userId;
    }
    public void setUserId(String userId) {
        this.userId = userId;
    }
    public Integer getCount() {
        return count;
    }
    public void setCount(Integer count) {
        this.count = count;
    }
    
    
    
}

