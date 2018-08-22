package com.timeline.vpn.model.enums;

import java.io.Serializable;

public enum LocationTypeNameEnum implements Serializable {
    FREE(0, "免费","完全免费","Free","All free to use","完全免费"), VIP1(1, "VIP1","积分2500以上升级VIP1","VIP1","score greater than 2100 to upgrade VIP1","现价-》25/月，250/年"),VIP2(2, "VIP2","积分4500以上升级VIP2","VIP2","score greater than 4100 to upgrade VIP2","现价-》35/月，300/年"),VIP3(3, "VIP3","推荐用户赚取VIP3","Paid","Recommend User for VIP3","500/年");
    Integer type;
    String name;
    String desc;
    String ename;
    String edesc;
    String descVpnb;

    LocationTypeNameEnum(Integer type, String name, String desc,String ename, String edesc,String descVpnb) {
        this.type = type;
        this.name = name;
        this.desc = desc;
        this.ename = ename;
        this.edesc = edesc;
        this.descVpnb = descVpnb;
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

    public String getDescVpnb() {
      return descVpnb;
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
