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
                () -> ShareLinkInfo.parse("ss://YWVzOnBhc3M@host:1"));
    }

    @Test
    void emptyInputIsRejected() {
        Assertions.assertThrows(IllegalArgumentException.class, () -> ShareLinkInfo.parse("   "));
    }

    @Test
    void trojanWithoutHostIsRejected() {
        Assertions.assertThrows(IllegalArgumentException.class, () -> ShareLinkInfo.parse("trojan://pass@:443"));
    }
}
