package com.timeline.vpn.model.po;
/**
 * @author gqli
 * @date 2016年12月14日 下午12:05:35
 * @version V1.0
 */
public class RadCheck {
    private Integer id;
    private String userName;
    private String attribute;
    private String op;
    private String value;
    public String getUserName() {
        return userName;
    }
    public void setUserName(String userName) {
        this.userName = userName;
    }
    public String getAttribute() {
        return attribute;
    }
    public void setAttribute(String attribute) {
        this.attribute = attribute;
    }
    public String getOp() {
        return op;
    }
    public void setOp(String op) {
        this.op = op;
    }
    public String getValue() {
        return value;
    }
    public void setValue(String value) {
        this.value = value;
    }
    public Integer getId() {
        return id;
    }
    public void setId(Integer id) {
        this.id = id;
    }
    
}

