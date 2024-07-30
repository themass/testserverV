package com.timeline.vpn.test;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Main {
    public static void main(String[] args) {
        // 输入的字符串
        String input = "#EXTM3U\n" +
                "#EXT-X-STREAM-INF:BANDWIDTH=2560000\n" +
                "https://v.rn80.xyz/hls/clz3lhpuf0000cvtpqm1za86o/clz3lhpuf0000cvtpqm1za86o-720/index.m3u8?v=6&exp=1722474000&auth=-zxyO_HOZWI-h6IBlWZ_gZw6mkggibGhbLDZrusToTk";

        // 定义正则表达式
        String regex = "^https.*$";

        // 创建 Pattern 对象
        Pattern pattern = Pattern.compile(regex, Pattern.MULTILINE);

        // 创建 matcher 对象
        Matcher matcher = pattern.matcher(input);

        // 检查是否匹配
        while (matcher.find()) {
            System.out.println("Match found: " + matcher.group());
        }
    }
}
