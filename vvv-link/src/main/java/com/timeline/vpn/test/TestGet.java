package com.timeline.vpn.test;

import com.timeline.vpn.common.utils.HttpCommonUtil;

/**
 * @Author： liguoqing
 * @Date： 2026/9/17 23:48
 * @Describe：
 */
public class TestGet {
    public static void main(String[] args) {
        String data = HttpCommonUtil.sendGet("https://rfd0i4.jstv800.com/video/view/307f181ddaea00791615");
        System.out.println(data);
    }
}
