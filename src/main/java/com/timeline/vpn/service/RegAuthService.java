package com.timeline.vpn.service;

/**
 * @author gqli
 * @date 2016年3月10日 上午10:30:25
 * @version V1.0
 */
public interface RegAuthService {
    public String reg(String channel);
    public boolean check(String channel,String code);
}

