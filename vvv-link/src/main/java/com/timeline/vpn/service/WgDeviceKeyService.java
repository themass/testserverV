package com.timeline.vpn.service;

import com.timeline.vpn.model.param.BaseQuery;

/**
 * WireGuard 设备公钥注册。
 *
 * @author gqli
 * @date 2026年11月1日
 * @version V1.0
 */
public interface WgDeviceKeyService {

    /**
     * 注册（或覆盖）设备的 WireGuard 公钥，并返回该设备唯一的隧道内地址。
     * 重复注册只覆盖公钥，地址不变。
     *
     * @param baseQuery  请求上下文
     * @param devId      设备标识；为空时回退到请求头里的设备号
     * @param publicKey  WireGuard 公钥，Base64
     * @return 设备的隧道内地址，CIDR，如 10.66.1.5/32
     */
    String register(BaseQuery baseQuery, String devId, String publicKey);

    /** 注销设备公钥；不存在时静默成功。 */
    void unregister(BaseQuery baseQuery, String devId);

    /** 查询已注册的公钥；未注册返回 null。 */
    String getPublicKey(String devId);

    /**
     * 某条线路的设备 peer 列表，每行 "公钥 地址/32"，供该线路的 WireGuard 服务器同步。
     * 免费线路返回全部设备；付费线路只返回所属用户等级够用的设备。
     */
    String peersText(int lineLevel);
}
