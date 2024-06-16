package vpn.model.po;

import java.util.Date;

/**
 * @author gqli
 * @date 2017年8月15日 下午6:05:17
 * @version V1.0
 */
public class VideoPo {
    private Integer id;
    private String name;
    private String url;
    private String pic;
    private String channel;
    private Date updateTime;
    private Float rate;
    private Integer showType; 
    private String videoType;
    private String baseurl;
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
    public String getVideoType() {
        return videoType;
    }
    public void setVideoType(String videoType) {
        this.videoType = videoType;
    }
    public String getBaseurl() {
        return baseurl;
    }
    public void setBaseurl(String baseurl) {
        this.baseurl = baseurl;
    }
    
}

