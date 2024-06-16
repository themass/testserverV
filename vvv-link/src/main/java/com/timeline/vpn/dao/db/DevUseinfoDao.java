package com.timeline.vpn.dao.db;

import com.timeline.vpn.model.po.DevUseinfoPo;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/**
 * @author gqli
 * @date 2016年12月14日 下午12:32:29
 * @version V1.0
 */
@Mapper
public interface DevUseinfoDao {
    public void insert(DevUseinfoPo po);
    public void update(DevUseinfoPo po);
    public DevUseinfoPo get(String devId);
    public int getCount(String name);
    public void updateRef(@Param("devId")String devId,@Param("ref")String ref);
    public int getRefCount(@Param("ref")String ref);
}

