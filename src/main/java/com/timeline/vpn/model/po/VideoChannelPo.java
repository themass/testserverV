package com.timeline.vpn.model.po;

import java.util.Date;

/**
 * @author gqli
 * @date 2017年8月15日 下午6:05:17
 * @version V1.0
 */
public class VideoChannelPo {
    private Integer id;
    private String name;
    private String url;
    private String pic;
    private String channel;
    private Date updateTime;
    private Float rate;
    private Integer showType; 
    private Integer count;
    private String channelType;
    private Integer type;
    private String baseurl;
    private int m;
    public String getBaseurl() {
        return baseurl;
    }
    public void setBaseurl(String baseurl) {
        this.baseurl = baseurl;
    }
 
    public Integer getType() {
        return type;
    }
    public void setType(Integer type) {
        this.type = type;
    }   
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
    public String getUrl() {
        return url;
    }
    public void setUrl(String url) {
        this.url = url;
    }
    public String getPic() {
        return pic;
    }
    public void setPic(String pic) {
        this.pic = pic;
    }
    public String getChannel() {
        return channel;
    }
    public void setChannel(String channel) {
        this.channel = channel;
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
    public Integer getCount() {
        return count;
    }
    public void setCount(Integer count) {
        this.count = count;
    }
    public String getChannelType() {
        return channelType;
    }
    public void setChannelType(String channelType) {
        this.channelType = channelType;
    }
    public int getM() {
        return m;
    }
    public void setM(int m) {
        this.m = m;
    }
    
    
}

