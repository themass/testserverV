package com.timeline.vpn.test;
/**
 * @author gqli
 * @date 2018年5月4日 下午6:49:22
 * @version V1.0
 */

public class DigVDetail {
    //版本
    private String v;
    //source 来源
    private String s;
    //sourceId 来源id
    private String sId;
    //广告位ID
    private Integer adId;
    //流量类型
    private String flow;
    //请求id
    private String rId;
    private String uni;
    
    public String getUni() {
        return uni;
    }
    public void setUni(String uni) {
        this.uni = uni;
    }
    public String getV() {
        return v;
    }
    public void setV(String v) {
        this.v = v;
    }
    public String getS() {
        return s;
    }
    public void setS(String s) {
        this.s = s;
    }
    public String getsId() {
        return sId;
    }
    public void setsId(String sId) {
        this.sId = sId;
    }
    public Integer getAdId() {
        return adId;
    }
    public void setAdId(Integer adId) {
        this.adId = adId;
    }
    public String getFlow() {
        return flow;
    }
    public void setFlow(String flow) {
        this.flow = flow;
    }
    public String getrId() {
        return rId;
    }
    public void setrId(String rId) {
        this.rId = rId;
    }
    
}

