package com.timeline.vpn.util;


import org.apache.commons.lang.StringUtils;

/**
 * 电话号加*
 *
 * @author: yong.lin
 * @date: 2015-12-15  11:30
 */
public class MobileFilterUtil {

    public static final String ASTERISK = "****";

    /**
     * 中间四位加***
     *
     * @param mobile
     * @return
     */
    public static String filter(String mobile) {
        if (StringUtils.isNotBlank(mobile)) {
            StringBuilder temp = new StringBuilder();
            temp.append(mobile.substring(0, 3)).append(ASTERISK)
                    .append(mobile.substring(7, mobile.length()));
            return temp.toString();
        }
        return mobile;

    }
}
