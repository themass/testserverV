package com.timeline.vpn.model.form;

/**
 * Created by liguoqing on 2019/5/31.
 */

public class CInfoForm {
    private String name;
    private String info;
    
    public String getName() {
        return name;
    }
    public void setName(String name) {
        this.name = name;
    }
    public String getInfo() {
        return info;
    }
    public void setInfo(String info) {
        this.info = info;
    }
    @Override
    public String toString() {
        return "CInfoForm [key=" + name + ", info=" + info + "]";
    }
    
}
