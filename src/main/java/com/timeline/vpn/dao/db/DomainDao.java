package com.timeline.vpn.dao.db;


import java.util.List;

import org.apache.ibatis.annotations.Param;

import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.DomainPo;

/**
 * @author gqli
 * @date 2015年12月14日 下午7:13:46
 * @version V1.0
 */
public interface DomainDao extends BaseDBDao<DomainPo> {
    List<DomainPo> getList(@Param("channel")String channel);
}

