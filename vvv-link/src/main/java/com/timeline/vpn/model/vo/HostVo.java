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

    // ---- WireGuard 多协议扩展字段，与 Android 端 HostVo 字段一一对应 ----
    /** 支持的协议，逗号分隔，如 "ikev2,wireguard"；为空/缺省时客户端按仅 ikev2 处理。 */
    private String protocols;
    /** WireGuard 服务端公钥，Base64。 */
    private String peerPublicKey;
    /** WireGuard 分配给客户端的隧道内地址，CIDR。 */
    private String clientAddress;
    /** WireGuard 隧道内 DNS，逗号分隔。 */
    private String dns;
    /** 建议 MTU；null 表示由客户端按协议默认值决定。 */
    private Integer mtu;

    /**
     * WireGuard 端点端口；null 表示客户端回退到 {@link #port}。
     * 同一节点 IKEv2 与 WireGuard 端口通常不同（500 vs 51820），必须分开下发。
     */
    private Integer wireGuardPort;

    // ---- VLESS+Reality 扩展字段，与 Android 端 HostVo 字段一一对应 ----
    private String vlessUuid;
    private String vlessFlow;
    private String realityServerName;
    private String realityPublicKey;
    private String realityShortId;
    private String realityFingerprint;

    // ---- 通用代理节点（sing-box 承载），见 sql/2026111100_proxy_links.sql ----
    /**
     * 各协议的分享链接，JSON 对象：协议名 -> 链接，如
     * {"trojan":"trojan://...","hysteria2":"hysteria2://..."}。
     * 链接就是服务端脚本 `vpn.sh singbox links` 的输出，客户端用与「自己的节点」相同的解析与连接路径，
     * 所以新增协议不需要改表结构，也不需要改客户端解析。
     */
    private String proxyLinks;

    public String getProxyLinks() {
        return proxyLinks;
    }

    public void setProxyLinks(String proxyLinks) {
        this.proxyLinks = proxyLinks;
    }

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

