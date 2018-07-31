package com.timeline.vpn.model.enums;

import java.io.Serializable;

public enum LocationTypeNameEnum implements Serializable {
    FREE(0, "免费","完全免费","Free","All free to use"), VIP1(1, "VIP1","积分2100以上升级VIP1","VIP1","score greater than 2100 to upgrade VIP1"),VIP2(2, "VIP2","积分4100以上升级VIP2","VIP2","score greater than 4100 to upgrade VIP2"),VIP3(3, "付费","15元购30天VIP3","Paid","$3/month for VIP3");
    Integer type;
    String name;
    String desc;
    String ename;
    String edesc;

    LocationTypeNameEnum(Integer type, String name, String desc,String ename, String edesc) {
        this.type = type;
        this.name = name;
        this.desc = desc;
        this.ename = ename;
        this.edesc = edesc;
    }

    public Integer getType() {
        return type;
    }

    public String getName() {
        return name;
    }

    public String getDesc() {
        return desc;
    }

    public String getEname() {
      return ename;
    }

    public String getEdesc() {
      return edesc;
    }

    public static LocationTypeNameEnum getModelType(Integer type) {
        for (LocationTypeNameEnum model : LocationTypeNameEnum.values()) {
            if (model.getType().equals(type)) {
                return model;
            }
        }
        throw null;
    }
}
