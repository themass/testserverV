package com.timeline.vpn.dao.db;

import org.apache.ibatis.annotations.Param;

import com.timeline.vpn.model.po.DevUseinfoPo;

/**
 * @author gqli
 * @date 2016年12月14日 下午12:32:29
 * @version V1.0
 */
public interface DevUseinfoDao {
    public void insert(DevUseinfoPo po);
    public void update(DevUseinfoPo po);
    public DevUseinfoPo get(String devId);
    public int getCount(String name);
    public void updateRef(@Param("devId")String devId,@Param("ref")String ref);
    public int getRefCount(@Param("ref")String ref);
}

