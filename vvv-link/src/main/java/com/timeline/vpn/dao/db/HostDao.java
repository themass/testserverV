package com.timeline.vpn.dao.db;

import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.HostPo;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * @author gqli
 * @date 2015年12月14日 下午7:13:46
 * @version V1.0
 */
@Mapper
public interface HostDao extends BaseDBDao<HostPo> {
    public HostPo get(int id);
    public List<HostPo> getRandom(String channel);
    public List<HostPo> getByLocation(int location);
}

