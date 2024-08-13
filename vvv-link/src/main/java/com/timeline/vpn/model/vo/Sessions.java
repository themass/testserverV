package com.timeline.vpn.model.vo;

import java.util.Date;

/**
 * @Author： liguoqing
 * @Date： 2024/8/13 20:24
 * @Describe：
 */
public class Sessions {
    public String name;
    public String setting = "";
    public int type;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getSetting() {
        return setting;
    }

    public void setSetting(String setting) {
        this.setting = setting;
    }

    public int getType() {
        return type;
    }

    public void setType(int type) {
        this.type = type;
    }
}
