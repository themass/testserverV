package com.timeline.vpn.dao.db;

import org.apache.ibatis.annotations.Param;

import com.timeline.vpn.model.po.RadacctState;

/**
 * @author gqli
 * @date 2016年12月14日 下午12:12:26
 * @version V1.0
 */
public interface RadacctDao {
    public RadacctState dateState(@Param("userName")String name);
   
}

