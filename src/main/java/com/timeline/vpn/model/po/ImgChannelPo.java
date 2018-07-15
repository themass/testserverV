package com.timeline.vpn.model.po;

import java.util.Date;

/**
 * @author gqli
 * @date 2017年8月17日 下午7:51:08
 * @version V1.0
 */
public class ImgChannelPo {
    private Integer id;
    private String baseurl;
    private String url;
    private String name;
    private String pic;
    private Date updateTime;
    private Float rate;
    private Integer showType;
    private Integer type;
    
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
    public String getBaseurl() {
        return baseurl;
    }
    public void setBaseurl(String baseurl) {
        this.baseurl = baseurl;
    }
    public String getUrl() {
        return url;
    }
    public void setUrl(String url) {
        this.url = url;
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
    
}

