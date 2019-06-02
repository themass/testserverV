package com.timeline.vpn.model.form;

import com.timeline.vpn.util.AES2;

/**
 * Created by liguoqing on 2019/5/31.
 */

public class CInfoForm {
    private String key;
    private String info;
    public String getKey() {
        return key;
    }
    public void setKey(String key) {
        this.key = key;
    }
    public String getInfo() {
        return info;
    }
    public void setInfo(String info) {
        this.info = info;
    }
    @Override
    public String toString() {
        return "CInfoForm [key=" + key + ", info=" + AES2.decode(info,"abcdefg!@#123456") + "]";
    }
    
}
