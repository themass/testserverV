package com.timeline.vpn.model.po;

import java.util.Date;

/**
 * @author gqli
 * @date 2015年11月9日 下午1:36:19
 * @version V1.0
 */
public class AppVersion {
    private int id;
    private String version;
    private String platform;
    private String content;
    private Date time;
    private String url;
    private String minBuild;
    private String maxBuild;
    private String channel;
    private Boolean showGdt;   

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getVersion() {
        return version;
    }

    public void setVersion(String version) {
        this.version = version;
    }

    public String getPlatform() {
        return platform;
    }

    public void setPlatform(String platform) {
        this.platform = platform;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public Date getTime() {
        return time;
    }

    public void setTime(Date time) {
        this.time = time;
    }

    public String getUrl() {
        return url;
    }

    public void setUrl(String url) {
        this.url = url;
    }

    public String getMinBuild() {
        return minBuild;
    }

    public void setMinBuild(String minBuild) {
        this.minBuild = minBuild;
    }

    public String getMaxBuild() {
        return maxBuild;
    }

    public void setMaxBuild(String maxBuild) {
        this.maxBuild = maxBuild;
    }

    public String getChannel() {
        return channel;
    }

    public void setChannel(String channel) {
        this.channel = channel;
    }

    public Boolean getShowGdt() {
        return showGdt;
    }

    public void setShowGdt(Boolean showGdt) {
        this.showGdt = showGdt;
    }


}
