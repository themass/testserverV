package com.timeline.vpn.model.param;

import java.util.Date;

import com.timeline.vpn.Constant;
import com.timeline.vpn.util.Md5;

public class DevApp {
    private String devId;
    private String versionName;
    private String version;
    private String platform;
    private String userIp;
    private String lang;
    private String sign;
    private long time;

    public DevApp(String devId,String userIp, String versionName, String version, String platform) {
        this.versionName = versionName;
        this.platform = platform;
        this.version = version;
        this.devId = devId;
        this.userIp = userIp;
    }
    public boolean check(){
        long now = new Date().getTime();
        if(now-time>Constant.MIN_TIME){
            return false;
        }
        if(!Md5.encode(devId+"|"+time).equals(sign))
            return false;
        return true;
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

    public String getVersionName() {
        return versionName;
    }

    public void setVersionName(String versionName) {
        this.versionName = versionName;
    }

    public String getUserIp() {
        return userIp;
    }

    public void setUserIp(String userIp) {
        this.userIp = userIp;
    }

    public String getDevId() {
        return devId;
    }

    public void setDevId(String devId) {
        this.devId = devId;
    }

    public String getLang() {
        return lang;
    }

    public void setLang(String lang) {
        this.lang = lang;
    }

    public String getSign() {
        return sign;
    }

    public void setSign(String sign) {
        this.sign = sign;
    }
    public long getTime() {
        return time;
    }
    public void setTime(long time) {
        this.time = time;
    }
    
}
