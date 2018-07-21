package com.timeline.vpn.model.enums;

import java.io.Serializable;

public enum LocationTypeNameEnum implements Serializable {
    FREE(0, "免费","完全免费"), VIP1(1, "VIP1","积分2000以上升级VIP1"),VIP2(2, "VIP2","积分4000以上升级VIP2"),VIP3(3, "付费","10月30天");
    Integer type;
    String name;
    String desc;

    LocationTypeNameEnum(Integer type, String name, String desc) {
        this.type = type;
        this.name = name;
        this.desc = desc;
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

    public static LocationTypeNameEnum getModelType(Integer type) {
        for (LocationTypeNameEnum model : LocationTypeNameEnum.values()) {
            if (model.getType().equals(type)) {
                return model;
            }
        }
        throw null;
    }
}
