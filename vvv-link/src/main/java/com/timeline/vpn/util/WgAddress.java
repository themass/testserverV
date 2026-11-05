package com.timeline.vpn.util;

import com.timeline.vpn.model.po.WgDeviceKeyPo;

import java.util.List;

/**
 * WireGuard 设备地址规划。所有 WireGuard 节点共用一个 /16 内网，每台设备在整个网络里只占一个 /32，
 * 地址由数据库里的 addrIndex 唯一决定，所以同一台设备连任何节点用的都是同一个地址。
 *
 * <pre>
 *   10.66.0.0/16      整个内网
 *   10.66.0.1         服务端（每个节点各自的接口地址，彼此独立）
 *   10.66.0.2 ~ 10.66.254.255   自动分配给设备（addrIndex 2 ~ 65279）
 *   10.66.255.0/24    保留给运维手工添加的 peer（vpn.sh wireguard add-peer），自动分配永远不会落进来
 * </pre>
 *
 * 网段改动需要同时改服务器脚本 modules/wireguard.sh 的 WG_SUBNET 和这里的 PREFIX。
 */
public final class WgAddress {

    /** 内网前两段。 */
    static final String PREFIX = "10.66";
    public static final int INDEX_MIN = 2;
    public static final int INDEX_MAX = 255 * 256 - 1;

    private WgAddress() {
    }

    /** addrIndex -> "10.66.x.y/32"。越界抛 IllegalArgumentException，不静默回绕到别的网段。 */
    public static String toCidr(int index) {
        if (index < INDEX_MIN || index > INDEX_MAX) {
            throw new IllegalArgumentException("addrIndex 超出范围 [" + INDEX_MIN + ", " + INDEX_MAX + "]: " + index);
        }
        return PREFIX + "." + (index / 256) + "." + (index % 256) + "/32";
    }

    /**
     * 服务器同步用的 peer 列表：每行 "公钥 地址/32"，按地址排序。
     * 不包含 devId 等内部标识。
     */
    /**
     * 线路等级与用户等级的判定，与 HostServerImpl.checkPermission 保持一致：
     * 免费线路（0 或 4）所有设备都可以用，其余线路要求用户等级 >= 线路等级。
     */
    public static boolean isFreeLine(int lineLevel) {
        return lineLevel == 0 || lineLevel == 4;
    }

    public static String formatPeers(List<WgDeviceKeyPo> devices) {
        StringBuilder sb = new StringBuilder();
        for (WgDeviceKeyPo d : devices) {
            if (d.getPublicKey() == null || d.getAddrIndex() == null) {
                continue;
            }
            sb.append(d.getPublicKey().trim()).append(' ').append(toCidr(d.getAddrIndex())).append('\n');
        }
        return sb.toString();
    }
}
