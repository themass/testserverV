package com.timeline.vpn.dao.db;

import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.FreeUseinfoPo;

/**
 * @author gqli
 * @date 2015年12月14日 下午7:13:46
 * @version V1.0
 */
public interface FreeUseinfoDao extends BaseDBDao<FreeUseinfoPo> {
    public FreeUseinfoPo get(String devId);
    public void update(FreeUseinfoPo po);
}

