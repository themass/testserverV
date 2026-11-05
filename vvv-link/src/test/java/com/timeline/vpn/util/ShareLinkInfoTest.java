package com.timeline.vpn.util;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;
import java.util.Base64;

class ShareLinkInfoTest {

    @Test
    void vmessReadsAddressPortAndName() {
        String json = "{\"v\":\"2\",\"ps\":\"香港 01\",\"add\":\"hk.example.com\",\"port\":\"443\",\"id\":\"uuid\"}";
        String link = "vmess://" + Base64.getEncoder().encodeToString(json.getBytes(StandardCharsets.UTF_8));
        ShareLinkInfo info = ShareLinkInfo.parse(link);
        Assertions.assertEquals("vmess", info.protocol);
        Assertions.assertEquals("香港 01", info.name);
        Assertions.assertEquals("hk.example.com", info.server);
        Assertions.assertEquals(443, info.port);
    }

    @Test
    void trojanReadsAddressPortAndFragmentName() {
        ShareLinkInfo info = ShareLinkInfo.parse("trojan://pass@jp.example.com:8443?sni=jp.example.com#Tokyo");
        Assertions.assertEquals("trojan", info.protocol);
        Assertions.assertEquals("Tokyo", info.name);
        Assertions.assertEquals("jp.example.com", info.server);
        Assertions.assertEquals(8443, info.port);
    }

    @Test
    void trojanWithoutPortDefaultsTo443() {
        ShareLinkInfo info = ShareLinkInfo.parse("trojan://pass@us.example.com");
        Assertions.assertEquals(443, info.port);
    }

    @Test
    void unsupportedSchemeIsRejected() {
        Assertions.assertThrows(IllegalArgumentException.class,
                () -> ShareLinkInfo.parse("ssr://YWVzOnBhc3M@host:1"));
    }

    @Test
    void emptyInputIsRejected() {
        Assertions.assertThrows(IllegalArgumentException.class, () -> ShareLinkInfo.parse("   "));
    }

    @Test
    void trojanWithoutHostIsRejected() {
        Assertions.assertThrows(IllegalArgumentException.class, () -> ShareLinkInfo.parse("trojan://pass@:443"));
    }

    @Test
    void vlessReadsAddressPortAndName() {
        ShareLinkInfo info = ShareLinkInfo.parse(
                "vless://11111111-2222-3333-4444-555555555555@sg.example.com:8443"
                        + "?security=reality&sni=www.microsoft.com&pbk=PK&sid=ab&type=tcp#%E6%96%B0%E5%8A%A0%E5%9D%A1");
        Assertions.assertEquals("vless", info.protocol);
        Assertions.assertEquals("新加坡", info.name);
        Assertions.assertEquals("sg.example.com", info.server);
        Assertions.assertEquals(8443, info.port);
    }

    @Test
    void vlessWithoutPortDefaultsTo443() {
        ShareLinkInfo info = ShareLinkInfo.parse("vless://uuid@sg.example.com?security=reality");
        Assertions.assertEquals(443, info.port);
        Assertions.assertEquals("vless node", info.name);
    }

    @Test
    void shadowsocksSip002ReadsHostAndPort() {
        String userinfo = Base64.getEncoder().encodeToString("aes-256-gcm:pass".getBytes(StandardCharsets.UTF_8));
        ShareLinkInfo info = ShareLinkInfo.parse("ss://" + userinfo + "@1.2.3.4:8388#SS%20Node");
        Assertions.assertEquals("shadowsocks", info.protocol);
        Assertions.assertEquals("SS Node", info.name);
        Assertions.assertEquals("1.2.3.4", info.server);
        Assertions.assertEquals(8388, info.port);
    }

    @Test
    void shadowsocksLegacyBase64ReadsHostAndPort() {
        String whole = Base64.getEncoder().encodeToString("aes-256-gcm:pass@5.6.7.8:9000".getBytes(StandardCharsets.UTF_8));
        ShareLinkInfo info = ShareLinkInfo.parse("ss://" + whole + "#legacy");
        Assertions.assertEquals("5.6.7.8", info.server);
        Assertions.assertEquals(9000, info.port);
        Assertions.assertEquals("legacy", info.name);
    }

    @Test
    void hysteria2AcceptsSpecialCharactersInPassword() {
        ShareLinkInfo info = ShareLinkInfo.parse("hysteria2://a/b+c=d@hy.example.com:4443?sni=hy.example.com#HY2");
        Assertions.assertEquals("hysteria2", info.protocol);
        Assertions.assertEquals("hy.example.com", info.server);
        Assertions.assertEquals(4443, info.port);
        Assertions.assertEquals("HY2", info.name);
    }

    @Test
    void hy2SchemeAlsoAccepted() {
        ShareLinkInfo info = ShareLinkInfo.parse("hy2://pw@hy.example.com");
        Assertions.assertEquals("hysteria2", info.protocol);
        Assertions.assertEquals(443, info.port);
    }

    @Test
    void ipv6HostIsParsed() {
        ShareLinkInfo info = ShareLinkInfo.parse("vless://uuid@[2001:db8::1]:443?security=tls#v6");
        Assertions.assertEquals("2001:db8::1", info.server);
        Assertions.assertEquals(443, info.port);
    }

    @Test
    void invalidPortIsRejected() {
        Assertions.assertThrows(IllegalArgumentException.class,
                () -> ShareLinkInfo.parse("vless://uuid@host.example.com:99999"));
        Assertions.assertThrows(IllegalArgumentException.class,
                () -> ShareLinkInfo.parse("hy2://pw@host.example.com:abc"));
    }

    @Test
    void missingHostIsRejectedForNewProtocols() {
        Assertions.assertThrows(IllegalArgumentException.class, () -> ShareLinkInfo.parse("vless://uuid"));
        Assertions.assertThrows(IllegalArgumentException.class, () -> ShareLinkInfo.parse("hy2://pw@:443"));
    }
}
