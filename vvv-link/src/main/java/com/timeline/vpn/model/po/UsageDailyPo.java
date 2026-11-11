package com.timeline.vpn.model.po;

import java.util.Date;

/** vpn.usage_daily 的一行：某台设备某一天的使用汇总。 */
public class UsageDailyPo {
    private Long id;
    private String devId;
    /** yyyy-MM-dd，客户端本地日期。 */
    private String day;
    private Long userId;
    private String userIp;
    private String version;
    private String platform;
    private int tzOffsetMin;
    private long connectedMs;
    private int sessions;
    private long rxBytes;
    private long txBytes;
    private int nodes;
    private String protocols;
    private int featureMask;
    private Date createdAt;
    private Date updatedAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getDevId() { return devId; }
    public void setDevId(String devId) { this.devId = devId; }
    public String getDay() { return day; }
    public void setDay(String day) { this.day = day; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public String getUserIp() { return userIp; }
    public void setUserIp(String userIp) { this.userIp = userIp; }
    public String getVersion() { return version; }
    public void setVersion(String version) { this.version = version; }
    public String getPlatform() { return platform; }
    public void setPlatform(String platform) { this.platform = platform; }
    public int getTzOffsetMin() { return tzOffsetMin; }
    public void setTzOffsetMin(int tzOffsetMin) { this.tzOffsetMin = tzOffsetMin; }
    public long getConnectedMs() { return connectedMs; }
    public void setConnectedMs(long connectedMs) { this.connectedMs = connectedMs; }
    public int getSessions() { return sessions; }
    public void setSessions(int sessions) { this.sessions = sessions; }
    public long getRxBytes() { return rxBytes; }
    public void setRxBytes(long rxBytes) { this.rxBytes = rxBytes; }
    public long getTxBytes() { return txBytes; }
    public void setTxBytes(long txBytes) { this.txBytes = txBytes; }
    public int getNodes() { return nodes; }
    public void setNodes(int nodes) { this.nodes = nodes; }
    public String getProtocols() { return protocols; }
    public void setProtocols(String protocols) { this.protocols = protocols; }
    public int getFeatureMask() { return featureMask; }
    public void setFeatureMask(int featureMask) { this.featureMask = featureMask; }
    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }
    public Date getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Date updatedAt) { this.updatedAt = updatedAt; }
}
