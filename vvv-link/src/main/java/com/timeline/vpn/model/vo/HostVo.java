package com.timeline.vpn.model.vo;

/**
 * @author gqli
 * @date 2016年3月7日 下午1:24:42
 * @version V1.0
 */
public class HostVo {
    private String gateway;
    private int port;
    private int location;
    private String cert;
    

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

}

