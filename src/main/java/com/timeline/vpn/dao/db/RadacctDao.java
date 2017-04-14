package com.timeline.vpn.dao.db;

import java.util.List;

import org.apache.ibatis.annotations.Param;

import com.timeline.vpn.model.po.Radacct;
import com.timeline.vpn.model.po.RadacctState;

/**
 * @author gqli
 * @date 2016年12月14日 下午12:12:26
 * @version V1.0
 */
public interface RadacctDao {
    public RadacctState dateState(@Param("userName")String name);
    public List<Radacct> selectIpLocal();
    public void updateIpLocal(@Param("list")List<Radacct>list);
   
}

