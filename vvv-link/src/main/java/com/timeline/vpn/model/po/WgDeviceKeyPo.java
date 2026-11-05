package com.timeline.vpn.model.po;

/**
 * WireGuard 客户端公钥注册记录。
 * <p>
 * 一台设备一条记录（devId 唯一）。客户端重装或重置身份后会重新生成密钥对，
 * 此时应覆盖旧公钥——见 {@code WgDeviceKeyMapper.xml} 的 upsert。
 *
 * @author gqli
 * @date 2026年11月1日
 * @version V1.0
 */
public class WgDeviceKeyPo {
    private Long id;
    /** 设备标识，对应 Android 端 DeviceInfoUtils.getDeviceId() */
    private String devId;
    /** WireGuard 公钥，Base64 */
    private String publicKey;
    /** 隧道内地址序号，见 {@link com.timeline.vpn.util.WgAddress}。 */
    private Integer addrIndex;
    /** 注册该设备的登录用户名；迁移前的旧记录为 null。 */
    private String userName;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getDevId() {
        return devId;
    }

    public void setDevId(String devId) {
        this.devId = devId;
    }

    public String getPublicKey() {
        return publicKey;
    }

    public void setPublicKey(String publicKey) {
        this.publicKey = publicKey;
    }

    public String getUserName() {
        return userName;
    }

    public void setUserName(String userName) {
        this.userName = userName;
    }

    public Integer getAddrIndex() {
        return addrIndex;
    }

    public void setAddrIndex(Integer addrIndex) {
        this.addrIndex = addrIndex;
    }

    @Override
    public String toString() {
        return "WgDeviceKeyPo{devId='" + devId + "'}";
    }
}
