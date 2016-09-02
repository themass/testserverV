package com.timeline.vpn.model.po;
/**
 * @author gqli
 * @date 2016年4月19日 下午7:38:04
 * @version V1.0
 */
public class ServerPo {
    private int id;
    private String name;
    private String pwd;
    private long expire;
    private int type;
    public int getId() {
        return id;
    }
    public void setId(int id) {
        this.id = id;
    }
    public String getName() {
        return name;
    }
    public void setName(String name) {
        this.name = name;
    }
    public String getPwd() {
        return pwd;
    }
    public void setPwd(String pwd) {
        this.pwd = pwd;
    }
    public long getExpire() {
        return expire;
    }
    public void setExpire(long expire) {
        this.expire = expire;
    }
    public int getType() {
        return type;
    }
    public void setType(int type) {
        this.type = type;
    }
    
}

