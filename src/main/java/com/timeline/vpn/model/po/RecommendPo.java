package com.timeline.vpn.model.po;

/**
 * @author gqli
 * @date 2016年4月19日 下午3:25:40
 * @version V1.0
 */
public class RecommendPo {
    private int id;
    private String title;
    private String actionUrl;
    private String img;
    private String desc;
    private String color;
    private float rate;
    private String imgPath;
    private int type;
    private Boolean adsShow;

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
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
        return imgPath+img;
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

    public String getImgPath() {
        return imgPath;
    }

    public void setImgPath(String imgPath) {
        this.imgPath = imgPath;
    }

    public int getType() {
        return type;
    }

    public void setType(int type) {
        this.type = type;
    }

    public Boolean getAdsShow() {
        return adsShow;
    }

    public void setAdsShow(Boolean adsShow) {
        this.adsShow = adsShow;
    }


}

