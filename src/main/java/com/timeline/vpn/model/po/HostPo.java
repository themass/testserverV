package com.timeline.vpn.model.po;

/**
 * @author gqli
 * @date 2016年3月7日 下午1:44:59
 * @version V1.0
 */
public class HostPo {
    private int id;
    private String gateway;
    private int port;
    private int location;
    private String cert;
    private int type;
    private float weight;
    private int hostId;
    private String com;
    private int needPing=1;
    private String showName;
    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getGateway() {
        return gateway;
    }

    public void setGateway(String gateway) {
        this.gateway = gateway;
    }

    public int getPort() {
        return port;
    }

    public void setPort(int port) {
        this.port = port;
    }

    public int getLocation() {
        return location;
    }

    public void setLocation(int location) {
        this.location = location;
    }

    public String getCert() {
        return cert;
    }

    public void setCert(String cert) {
        this.cert = cert;
    }

   

    public int getType() {
        return type;
    }

    public void setType(int type) {
        this.type = type;
    }

    public float getWeight() {
        return weight;
    }

    public void setWeight(float weight) {
        this.weight = weight;
    }

    public int getHostId() {
        return hostId;
    }

    public void setHostId(int hostId) {
        this.hostId = hostId;
    }

    public String getCom() {
        return com;
    }

    public void setCom(String com) {
        this.com = com;
    }

    public int getNeedPing() {
        return needPing;
    }

    public void setNeedPing(int needPing) {
        this.needPing = needPing;
    }

    public String getShowName() {
        return showName;
    }

    public void setShowName(String showName) {
        this.showName = showName;
    }

}

