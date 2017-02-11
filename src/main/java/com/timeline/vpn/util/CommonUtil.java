package com.timeline.vpn.util;

import java.util.regex.Pattern;

import org.apache.commons.lang3.RandomUtils;

/**
 * @author gqli
 * @date 2015年12月15日 下午1:04:57
 * @version V1.0
 */
public class CommonUtil {
    private static final int CODE_START = 1000;
    private static final int CODE_END = 9999;
    private static final Pattern pattern = Pattern.compile("[0-9A-Za-z]");
    public static String generateCode() {
        return String.valueOf(RandomUtils.nextInt(CODE_START, CODE_END));
    }
    public static boolean isNumAndEnglish(String str){
        return pattern.matcher(str).matches();
    }
}

