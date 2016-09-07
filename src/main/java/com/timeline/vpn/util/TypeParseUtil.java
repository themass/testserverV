package com.timeline.vpn.util;

/**
 * @author gqli
 * @date 2016年3月2日 下午5:19:17
 * @version V1.0
 */
public class TypeParseUtil {
    public static Integer parseToInteger(String str) {
        try {
            return Integer.parseInt(str);
        } catch (NumberFormatException e) {
            return null;
        }
    }

    public static Long parseToLong(String str) {
        try {
            return Long.parseLong(str);
        } catch (NumberFormatException e) {
            return null;
        }
    }
}

