package com.timeline.vpn.util;

import com.timeline.vpn.model.po.WgDeviceKeyPo;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;

class WgAddressTest {

    @Test
    void firstIndexIsDotTwoAndServerDotOneIsNeverAssigned() {
        Assertions.assertEquals("10.66.0.2/32", WgAddress.toCidr(WgAddress.INDEX_MIN));
        Assertions.assertThrows(IllegalArgumentException.class, () -> WgAddress.toCidr(1));
        Assertions.assertThrows(IllegalArgumentException.class, () -> WgAddress.toCidr(0));
    }

    @Test
    void indexCrossesThirdOctetAtMultiplesOf256() {
        Assertions.assertEquals("10.66.0.255/32", WgAddress.toCidr(255));
        Assertions.assertEquals("10.66.1.0/32", WgAddress.toCidr(256));
        Assertions.assertEquals("10.66.1.1/32", WgAddress.toCidr(257));
    }

    @Test
    void lastAutoIndexStaysOutOfTheManualBlock() {
        Assertions.assertEquals("10.66.254.255/32", WgAddress.toCidr(WgAddress.INDEX_MAX));
        // 10.66.255.0/24 留给运维手工添加的 peer
        Assertions.assertThrows(IllegalArgumentException.class, () -> WgAddress.toCidr(WgAddress.INDEX_MAX + 1));
    }

    @Test
    void formatPeersWritesKeyAndAddressOnly() {
        List<WgDeviceKeyPo> list = new ArrayList<>();
        list.add(po("secret-device-id", "KEY1=", 2));
        list.add(po("another-device", "KEY2=", 300));
        String text = WgAddress.formatPeers(list);
        Assertions.assertEquals("KEY1= 10.66.0.2/32\nKEY2= 10.66.1.44/32\n", text);
        Assertions.assertFalse(text.contains("device"), "内部设备标识不能出现在同步输出里");
    }

    @Test
    void formatPeersSkipsRowsWithoutAddress() {
        List<WgDeviceKeyPo> list = new ArrayList<>();
        list.add(po("d", "KEY1=", null));
        Assertions.assertEquals("", WgAddress.formatPeers(list));
    }

    private static WgDeviceKeyPo po(String devId, String key, Integer index) {
        WgDeviceKeyPo p = new WgDeviceKeyPo();
        p.setDevId(devId);
        p.setPublicKey(key);
        p.setAddrIndex(index);
        return p;
    }
}
