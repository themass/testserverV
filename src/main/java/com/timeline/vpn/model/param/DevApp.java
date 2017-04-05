package com.timeline.vpn.model.param;

import java.util.Date;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.timeline.vpn.Constant;
import com.timeline.vpn.util.DateTimeUtils;
import com.timeline.vpn.util.Md5;

public class DevApp {
    private static final Logger LOGGER =
            LoggerFactory.getLogger(DevApp.class);
    private String devId;
    private String versionName;
    private String version;
    private String platform;
    private String userIp;
    private String lang;
    private String sign;
    private long time;
    private String authKey;
    private boolean isTest;
    private String host;
    private String lon;
    private String lat;
    private String tokenHeader;
    private String channel;
    public DevApp(){}
    public DevApp(String devId, String userIp, String versionName, String version,
            String platform) {
        this.versionName = versionName;
        this.platform = platform;
        this.version = version;
        this.devId = devId;
        this.userIp = userIp;
    }

    public boolean check() {
        long now = new Date().getTime();
        if(platform==null||version==null||devId==null){
            LOGGER.error("check fail :platform="+platform+",version="+version+",devId="+devId);
            return false;
        }
        if (now - time > Constant.MIN_TIME) {
            LOGGER.error("check fail :now="+now+",time="+time);
            return false;
        }
        if (!Md5.encode(devId + "|" + time).equals(sign)){
            LOGGER.error("check fail :sign="+sign+",devId="+devId+",time="+time);
            return false;
        }
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

    public String getAuthKey() {
        return authKey;
    }

    public void setAuthKey(String authKey) {
        this.authKey = authKey;
    }

    public boolean isTest() {
        return isTest;
    }

    public void setTest(boolean isTest) {
        this.isTest = isTest;
    }

    public String getHost() {
        return host;
    }
    public void setHost(String host) {
        this.host = host;
    }
    
    public String getLon() {
        return lon;
    }
    public void setLon(String lon) {
        this.lon = lon;
    }
    public String getLat() {
        return lat;
    }
    public void setLat(String lat) {
        this.lat = lat;
    }
    
    public String getTokenHeader() {
        return tokenHeader;
    }
    public void setTokenHeader(String tokenHeader) {
        this.tokenHeader = tokenHeader;
    }
    
    public String getChannel() {
        return channel;
    }
    public void setChannel(String channel) {
        this.channel = channel;
    }
    @Override
    public String toString() {
        return "DevApp [devId=" + devId + ", versionName=" + versionName + ", version=" + version
                + ", platform=" + platform + ", userIp=" + userIp + ", lang=" + lang + ", sign="
                + sign + ", time=" + time + ", authKey=" + authKey + ", isTest=" + isTest
                + ", host=" + host + ", lon=" + lon + ", lat=" + lat + ", tokenHeader="
                + tokenHeader + ", channel=" + channel + "]";
    }
    

}
