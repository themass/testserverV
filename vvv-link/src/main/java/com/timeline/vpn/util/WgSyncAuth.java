package com.timeline.vpn.util;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

/**
 * WireGuard 服务器同步 peer 列表时的令牌校验。令牌配在 secrets.properties 的 wg.syncToken，
 * 与服务器 /etc/wireguard/sync.env 里的 WG_SYNC_TOKEN 一致。
 */
public final class WgSyncAuth {

    /** 令牌至少这么长，避免配成 123456 之类的弱值后接口等于没设防。 */
    static final int MIN_LENGTH = 24;

    private WgSyncAuth() {
    }

    /**
     * @param provided 请求头里的令牌
     * @param expected 服务端配置的令牌
     * @return 校验通过。服务端没配、配得太短、请求没带，都返回 false；比较用固定时间，不泄露前缀匹配长度。
     */
    public static boolean matches(String provided, String expected) {
        if (expected == null || expected.length() < MIN_LENGTH || provided == null) {
            return false;
        }
        return MessageDigest.isEqual(provided.getBytes(StandardCharsets.UTF_8),
                expected.getBytes(StandardCharsets.UTF_8));
    }
}
