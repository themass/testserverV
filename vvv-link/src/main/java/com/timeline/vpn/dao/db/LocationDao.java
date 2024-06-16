package com.timeline.vpn.dao.db;

import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.LocationPo;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * @author gqli
 * @date 2016年8月9日 下午12:23:47
 * @version V1.0
 */
@Mapper
public interface LocationDao extends BaseDBDao<LocationPo> {
    public LocationPo get(@Param("id")int id);
    
    public List<LocationPo> getAllInfo();
    public List<LocationPo> getAllInfoVpnb();

}

