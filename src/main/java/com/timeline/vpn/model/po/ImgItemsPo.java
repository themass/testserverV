package com.timeline.vpn.model.po;

import java.util.Date;

/**
 * @author gqli
 * @date 2017年8月21日 下午8:22:50
 * @version V1.0
 */
public class ImgItemsPo {
    private Integer id;
    private String name;
    private String channel;
    private String url;
    private Date updateTime;
    private String fileDate;
    private String baseUrl;
    private int pics;
    private String pic;
    private Float rate;
    private Integer showType;
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
    public String getChannel() {
        return channel;
    }
    public void setChannel(String channel) {
        this.channel = channel;
    }
    public String getUrl() {
        return url;
    }
    public void setUrl(String url) {
        this.url = url;
    }
    public Date getUpdateTime() {
        return updateTime;
    }
    public void setUpdateTime(Date updateTime) {
        this.updateTime = updateTime;
    }
    public String getFileDate() {
        return fileDate;
    }
    public void setFileDate(String fileDate) {
        this.fileDate = fileDate;
    }
    public String getBaseUrl() {
        return baseUrl;
    }
    public void setBaseUrl(String baseUrl) {
        this.baseUrl = baseUrl;
    }
    public int getPics() {
        return pics;
    }
    public void setPics(int pics) {
        this.pics = pics;
    }
    public String getPic() {
        return pic;
    }
    public void setPic(String pic) {
        this.pic = pic;
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
    
   
}

