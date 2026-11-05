package com.timeline.vpn.model.vo;

/**
 * WireGuard 注册结果。clientAddress 是该设备在整个 WireGuard 网络里唯一的隧道内地址（CIDR），
 * 客户端建隧道时用它，而不是节点列表里的 clientAddress。
 */
public class WgRegisterVo {
    public String clientAddress;

    public WgRegisterVo() {
    }

    public WgRegisterVo(String clientAddress) {
        this.clientAddress = clientAddress;
    }
}
