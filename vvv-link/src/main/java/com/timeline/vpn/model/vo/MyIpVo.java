package com.timeline.vpn.model.vo;

/** 服务端看到的请求方 IP，以及查到的城市（网络体检用：经过 VPN 时就是节点出口）。 */
public class MyIpVo {
    public String ip;
    /** 省份（查不到时为空） */
    public String province;
    /** 城市（查不到时为空） */
    public String city;

    public MyIpVo() {
    }

    public MyIpVo(String ip) {
        this.ip = ip;
    }
}
