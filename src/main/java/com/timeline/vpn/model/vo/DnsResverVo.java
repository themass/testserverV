package com.timeline.vpn.model.vo;

import java.util.List;

/**
 * @author gqli
 * @date 2016年12月16日 下午3:49:34
 * @version V1.0
 */
public class DnsResverVo {
    private List<DnsResverItemVo> val;
    private String key;
    public DnsResverVo(String key, List<DnsResverItemVo> val){
        this.key = key;
        this.val = val;
    }
    public List<DnsResverItemVo> getVal() {
        return val;
    }
    public void setVal(List<DnsResverItemVo> val) {
        this.val = val;
    }
    public String getKey() {
        return key;
    }
    public void setKey(String key) {
        this.key = key;
    }
    
}

