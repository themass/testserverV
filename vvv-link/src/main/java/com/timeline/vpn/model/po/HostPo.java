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

    // ---- WireGuard 多协议扩展字段（见 sql/2026110100_wireguard.sql） ----
    /** 该节点支持的协议，逗号分隔，如 "ikev2,wireguard"；为空表示仅 ikev2。 */
    private String protocols;
    /** WireGuard 服务端公钥，Base64。 */
    private String peerPublicKey;
    /** WireGuard 分配给客户端的地址，CIDR。 */
    private String clientAddress;
    /** WireGuard 隧道内 DNS，逗号分隔。 */
    private String dns;
    /** 建议 MTU；null 表示由协议默认值决定。 */
    private Integer mtu;

    /**
     * WireGuard 端点端口；null 表示客户端回退到 {@link #port}。
     * 同一节点 IKEv2 与 WireGuard 端口通常不同（500 vs 51820），必须分开下发。
     */
    private Integer wireGuardPort;

    // ---- VLESS+Reality 扩展字段（见 sql/2026110300_vless_reality.sql） ----
    /** VLESS 用户 UUID。 */
    private String vlessUuid;
    /** VLESS 流控，如 "xtls-rprx-vision"。 */
    private String vlessFlow;
    /** Reality 借用的真实网站域名（握手 SNI）。 */
    private String realityServerName;
    /** Reality 服务端公钥，Base64。 */
    private String realityPublicKey;
    /** Reality short ID。 */
    private String realityShortId;
    /** Reality TLS 指纹伪装，如 "chrome"。 */
    private String realityFingerprint;

    public String getVlessUuid() {
        return vlessUuid;
    }

    public void setVlessUuid(String vlessUuid) {
        this.vlessUuid = vlessUuid;
    }

    public String getVlessFlow() {
        return vlessFlow;
    }

    public void setVlessFlow(String vlessFlow) {
        this.vlessFlow = vlessFlow;
    }

    public String getRealityServerName() {
        return realityServerName;
    }

    public void setRealityServerName(String realityServerName) {
        this.realityServerName = realityServerName;
    }

    public String getRealityPublicKey() {
        return realityPublicKey;
    }

    public void setRealityPublicKey(String realityPublicKey) {
        this.realityPublicKey = realityPublicKey;
    }

    public String getRealityShortId() {
        return realityShortId;
    }

    public void setRealityShortId(String realityShortId) {
        this.realityShortId = realityShortId;
    }

    public String getRealityFingerprint() {
        return realityFingerprint;
    }

    public void setRealityFingerprint(String realityFingerprint) {
        this.realityFingerprint = realityFingerprint;
    }

    public String getProtocols() {
        return protocols;
    }

    public void setProtocols(String protocols) {
        this.protocols = protocols;
    }

    public String getPeerPublicKey() {
        return peerPublicKey;
    }

    public void setPeerPublicKey(String peerPublicKey) {
        this.peerPublicKey = peerPublicKey;
    }

    public String getClientAddress() {
        return clientAddress;
    }

    public void setClientAddress(String clientAddress) {
        this.clientAddress = clientAddress;
    }

    public String getDns() {
        return dns;
    }

    public void setDns(String dns) {
        this.dns = dns;
    }

    public Integer getMtu() {
        return mtu;
    }

    public void setMtu(Integer mtu) {
        this.mtu = mtu;
    }

    public Integer getWireGuardPort() {
        return wireGuardPort;
    }

    public void setWireGuardPort(Integer wireGuardPort) {
        this.wireGuardPort = wireGuardPort;
    }

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

    @Override
    public String toString() {
        return "ipport:"+com+";"+gateway+";"+id+";"+weight+showName;
    }

}

