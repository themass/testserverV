package com.timeline.vpn.dao.db;

import java.util.List;

import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.HostPo;

/**
 * @author gqli
 * @date 2015年12月14日 下午7:13:46
 * @version V1.0
 */
public interface HostDao extends BaseDBDao<HostPo> {
    public HostPo get(int id);
    public List<HostPo> getRandom();
    public List<HostPo> getByLocation(int location);
}

