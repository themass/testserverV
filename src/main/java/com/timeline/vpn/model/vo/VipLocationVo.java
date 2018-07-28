package com.timeline.vpn.model.vo;

import java.util.List;

/**
 * @author gqli
 * @date 2016年8月9日 下午12:20:59
 * @version V1.0
 */
public class VipLocationVo {
    private int type;
    private int count;
    private String name;
    private String desc;
    private String ename;
    private String edesc;
    private List<LocationVo> list;
    public int getType() {
        return type;
    }
    public void setType(int type) {
        this.type = type;
    }
    public String getName() {
        return name;
    }
    public void setName(String name) {
        this.name = name;
    }
    public int getCount() {
        return count;
    }
    public void setCount(int count) {
        this.count = count;
    }
    public String getDesc() {
        return desc;
    }
    public void setDesc(String desc) {
        this.desc = desc;
    }
    public List<LocationVo> getList() {
        return list;
    }
    public void setList(List<LocationVo> list) {
        this.list = list;
    }
    public String getEname() {
      return ename;
    }
    public void setEname(String ename) {
      this.ename = ename;
    }
    public String getEdesc() {
      return edesc;
    }
    public void setEdesc(String edesc) {
      this.edesc = edesc;
    }
    

    
}

