package com.timeline.vpn.model.po;

import java.util.Date;

/**
 * @author gqli
 * @date 2016年4月19日 下午1:55:55
 * @version V1.0
 */
public class FreeUseinfoPo {
    private String devId;
    private String platform;
    private String version;
    private Date creatTime;
    private Date lastUpdate;
    private long useTime;
    public String getDevId() {
        return devId;
    }
    public void setDevId(String devId) {
        this.devId = devId;
    }
    public String getPlatform() {
        return platform;
    }
    public void setPlatform(String platform) {
        this.platform = platform;
    }
    public String getVersion() {
        return version;
    }
    public void setVersion(String version) {
        this.version = version;
    }
    public Date getCreatTime() {
        return creatTime;
    }
    public void setCreatTime(Date creatTime) {
        this.creatTime = creatTime;
    }
    public Date getLastUpdate() {
        return lastUpdate;
    }
    public void setLastUpdate(Date lastUpdate) {
        this.lastUpdate = lastUpdate;
    }
    public long getUseTime() {
        return useTime;
    }
    public void setUseTime(long useTime) {
        this.useTime = useTime;
    }
    
    
}

