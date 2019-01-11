package com.timeline.vpn.dao.db;

import java.util.List;

import org.apache.ibatis.annotations.Param;

import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.LocationPo;

/**
 * @author gqli
 * @date 2016年8月9日 下午12:23:47
 * @version V1.0
 */
public interface LocationV2Dao extends BaseDBDao<LocationPo> {
    public LocationPo get(@Param("id")int id);
    public LocationPo getByHostId(@Param("hostId")int hostId);
    public List<LocationPo> getAllInfoVpn();
    public List<LocationPo> getAllInfoVpnb();

}

