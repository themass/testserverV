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
     * 注册（或覆盖）设备的 WireGuard 公钥。
     *
     * @param baseQuery  请求上下文
     * @param devId      设备标识；为空时回退到请求头里的设备号
     * @param publicKey  WireGuard 公钥，Base64
     */
    void register(BaseQuery baseQuery, String devId, String publicKey);

    /** 注销设备公钥；不存在时静默成功。 */
    void unregister(BaseQuery baseQuery, String devId);

    /** 查询已注册的公钥；未注册返回 null。 */
    String getPublicKey(String devId);
}
