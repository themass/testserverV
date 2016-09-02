package com.timeline.vpn.util;

/**
*
 * @author gqli
 * @date 2015年8月4日 下午4:58:00
 * @version V1.0
 */
public class PageNumUtil {
    public static int offsetToPageNum(int offset, int limit) {
        return offset / limit + 1;
    }
}

