package com.timeline.vpn.model.vo;

import java.util.Date;

import com.timeline.vpn.Constant;

/**
 * @author gqli
 * @date 2016年3月10日 下午4:41:23
 * @version V1.0
 */
public class RecommendVo {
    private String title;
    private String actionUrl;
    private String img;
    private String desc;
    private String color;
    private float rate;
    private Boolean adsShow;
    private Boolean adsPopShow;
    // 0  正常显示，1 图片模糊+文字，2只有文字没有图片
    private int showType;
    private Date createTime;
    private Integer id;
    private String param;
    private String minVersion;
    private Boolean newShow;
    private String showLogo;
    private Object extra;
    private int type;
    private String baseurl;
    private int dataType = Constant.dataType_RECOMMENT;
    public String getBaseurl() {
        return baseurl;
    }
    public void setBaseurl(String baseurl) {
        this.baseurl = baseurl;
    }
    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getActionUrl() {
        return actionUrl;
    }

    public void setActionUrl(String actionUrl) {
        this.actionUrl = actionUrl;
    }

    public String getImg() {
        return img;
    }

    public void setImg(String img) {
        this.img = img;
    }

    public String getDesc() {
        return desc;
    }

    public void setDesc(String desc) {
        this.desc = desc;
    }

    public String getColor() {
        return color;
    }

    public void setColor(String color) {
        this.color = color;
    }

    public float getRate() {
        return rate;
    }

    public void setRate(float rate) {
        this.rate = rate;
    }

    public Boolean getAdsShow() {
        return adsShow;
    }

    public void setAdsShow(Boolean adsShow) {
        this.adsShow = adsShow;
    }

    public Boolean getAdsPopShow() {
        return adsPopShow;
    }

    public void setAdsPopShow(Boolean adsPopShow) {
        this.adsPopShow = adsPopShow;
    }

    public int getShowType() {
        return showType;
    }

    public void setShowType(int showType) {
        this.showType = showType;
    }

    public Date getCreateTime() {
        return createTime;
    }

    public void setCreateTime(Date createTime) {
        this.createTime = createTime;
    }

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getParam() {
        return param;
    }

    public void setParam(String param) {
        this.param = param;
    }

    public String getMinVersion() {
        return minVersion;
    }

    public void setMinVersion(String minVersion) {
        this.minVersion = minVersion;
    }

    public Boolean getNewShow() {
        return newShow;
    }

    public void setNewShow(Boolean newShow) {
        this.newShow = newShow;
    }

    public String getShowLogo() {
        return showLogo;
    }

    public void setShowLogo(String showLogo) {
        this.showLogo = showLogo;
    }

    public Object getExtra() {
        return extra;
    }

    public void setExtra(Object extra) {
        this.extra = extra;
    }

    public int getType() {
        return type;
    }

    public void setType(int type) {
        this.type = type;
    }

    public int getDataType() {
        return dataType;
    }

    public void setDataType(int dataType) {
        this.dataType = dataType;
    }
    
    
}

