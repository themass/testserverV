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
    private Boolean logUp;
    private StateUseVo stateUse;
    private String dnspodIp;
    private Boolean needDnspod=true;
    private String vpnUrl;

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

    public Boolean getLogUp() {
        return logUp;
    }

    public void setLogUp(Boolean logUp) {
        this.logUp = logUp;
    }
    public StateUseVo getStateUse() {
        return stateUse;
    }

    public void setStateUse(StateUseVo stateUse) {
        this.stateUse = stateUse;
    }

    public String getDnspodIp() {
        return dnspodIp;
    }

    public void setDnspodIp(String dnspodIp) {
        this.dnspodIp = dnspodIp;
    }

    public Boolean getNeedDnspod() {
        return needDnspod;
    }

    public void setNeedDnspod(Boolean needDnspod) {
        this.needDnspod = needDnspod;
    }

    public String getVpnUrl() {
        return vpnUrl;
    }

    public void setVpnUrl(String vpnUrl) {
        this.vpnUrl = vpnUrl;
    }

    @Override
    public String toString() {
        return "VersionInfoVo [version=" + version + ", content=" + content + ", url=" + url
                + ", minBuild=" + minBuild + ", maxBuild=" + maxBuild + "]";
    }
}
