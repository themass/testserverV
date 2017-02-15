package com.timeline.vpn.dao.db;

import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.AppVersion;

/**
 * @author gqli
 * @date 2015年11月9日 下午1:39:30
 * @version V1.0
 */
public interface VersionDao extends BaseDBDao<AppVersion> {
    public AppVersion getLast(String platform,String channel);

}
