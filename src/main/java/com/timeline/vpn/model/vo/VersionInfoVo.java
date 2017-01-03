package com.timeline.vpn.model.vo;

/**
 * @author gqli
 * @date 2015年11月9日 下午1:36:19
 * @version V1.0
 */
public class VersionInfoVo {
    private String version;
    private String content;
    private String url;
    private int minBuild;
    private int maxBuild;
    private Boolean adsShow;

    public String getVersion() {
        return version;
    }

    public void setVersion(String version) {
        this.version = version;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getUrl() {
        return url;
    }

    public void setUrl(String url) {
        this.url = url;
    }

    public int getMinBuild() {
        return minBuild;
    }

    public void setMinBuild(String minBuild) {
        this.minBuild = Integer.parseInt(minBuild);
    }

    public int getMaxBuild() {
        return maxBuild;
    }

    public void setMaxBuild(String maxBuild) {
        this.maxBuild = Integer.parseInt(maxBuild);
    }

    public Boolean getAdsShow() {
        return adsShow;
    }

    public void setAdsShow(Boolean adsShow) {
        this.adsShow = adsShow;
    }

    @Override
    public String toString() {
        return "VersionInfoVo [version=" + version + ", content=" + content + ", url=" + url
                + ", minBuild=" + minBuild + ", maxBuild=" + maxBuild + "]";
    }
}
