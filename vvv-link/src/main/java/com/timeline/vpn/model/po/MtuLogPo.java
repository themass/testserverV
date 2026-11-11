package com.timeline.vpn.model.po;

import java.util.Date;

/** vpn.mtu_log 的一行：一次连接的 MTU 与探针结果。 */
public class MtuLogPo {
    private Long id;
    private String devId;
    private String userIp;
    private String node;
    private String protocol;
    private String netType;
    private String carrier;
    private int linkMtu;
    private int mtu;
    private String probe;
    private boolean retried;
    private Date createdAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getDevId() { return devId; }
    public void setDevId(String devId) { this.devId = devId; }
    public String getUserIp() { return userIp; }
    public void setUserIp(String userIp) { this.userIp = userIp; }
    public String getNode() { return node; }
    public void setNode(String node) { this.node = node; }
    public String getProtocol() { return protocol; }
    public void setProtocol(String protocol) { this.protocol = protocol; }
    public String getNetType() { return netType; }
    public void setNetType(String netType) { this.netType = netType; }
    public String getCarrier() { return carrier; }
    public void setCarrier(String carrier) { this.carrier = carrier; }
    public int getLinkMtu() { return linkMtu; }
    public void setLinkMtu(int linkMtu) { this.linkMtu = linkMtu; }
    public int getMtu() { return mtu; }
    public void setMtu(int mtu) { this.mtu = mtu; }
    public String getProbe() { return probe; }
    public void setProbe(String probe) { this.probe = probe; }
    public boolean isRetried() { return retried; }
    public void setRetried(boolean retried) { this.retried = retried; }
    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }
}
