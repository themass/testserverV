package com.timeline.vpn.dao.db;


import java.util.List;

import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.AppInfoPo;

/**
 * @author gqli
 * @date 2015年12月14日 下午7:13:46
 * @version V1.0
 */
public interface AppInfoDao extends BaseDBDao<AppInfoPo> {
    List<AppInfoPo> getAllDon();
}

