package com.timeline.vpn.model.vo;

/** 服务端看到的请求方 IP（网络体检用：经过 VPN 时就是节点出口 IP）。 */
public class MyIpVo {
    public String ip;

    public MyIpVo() {
    }

    public MyIpVo(String ip) {
        this.ip = ip;
    }
}
