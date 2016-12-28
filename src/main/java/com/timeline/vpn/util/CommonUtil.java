package com.timeline.vpn.util;

import org.apache.commons.lang3.RandomUtils;

/**
 * @author gqli
 * @date 2015年12月15日 下午1:04:57
 * @version V1.0
 */
public class CommonUtil {
    private static final int CODE_START = 1000;
    private static final int CODE_END = 9999;

    public static String generateCode() {
        return String.valueOf(RandomUtils.nextInt(CODE_START, CODE_END));
    }
}

