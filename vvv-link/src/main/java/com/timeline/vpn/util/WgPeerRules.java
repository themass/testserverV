package com.timeline.vpn.util;

/**
 * 线路等级与设备准入的判定。同步名单时逐设备用这里的规则过滤，与 HostServerImpl.checkPermission 保持一致。
 */
public final class WgPeerRules {

    private WgPeerRules() {
    }

    /**
     * @param lineLevel 服务器所属线路的等级：0 或 4 为免费线路，1、2… 为对应的 VIP 等级
     * @param userLevel 设备所属用户当前的等级；未知（旧设备）传 null
     * @return 该设备能否出现在这条线路的名单里
     */
    public static boolean allowed(int lineLevel, Integer userLevel) {
        if (lineLevel == 0 || lineLevel == 4) {
            return true;
        }
        return userLevel != null && userLevel >= lineLevel;
    }
}
