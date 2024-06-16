package com.timeline.vpn.common.utils;

import lombok.extern.slf4j.Slf4j;

import java.net.Inet4Address;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.util.Enumeration;
import java.util.LinkedList;
import java.util.List;

/**
 * @Author： liguoqing
 * @Date： 2024/5/17 11:07
 * @Describe：
 */
@Slf4j
public class IpUtils {

    public static String getLocalIP() {
        try {
            Enumeration<NetworkInterface> networkInterfaces = NetworkInterface.getNetworkInterfaces();
            List<InetAddress> addresses = new LinkedList<>();
            while (networkInterfaces.hasMoreElements()) {
                NetworkInterface networkInterface = networkInterfaces.nextElement();
                Enumeration<InetAddress> inetAddressEnumeration = networkInterface.getInetAddresses();
                while (inetAddressEnumeration.hasMoreElements()) {
                    InetAddress inetAddress = inetAddressEnumeration.nextElement();
                    if (!inetAddress.isLoopbackAddress() && inetAddress instanceof Inet4Address) {
                        addresses.add(inetAddress);
                    }
                }
            }

            // 可以选择返回第一个非回环地址，或者根据需要选择特定的地址
            if (!addresses.isEmpty()) {
                return addresses.get(0).getHostAddress();
            }
            return "def";
        } catch (Exception e) {
            log.error("无法获取本机ip", e);
            return "def";
        }
    }
}
