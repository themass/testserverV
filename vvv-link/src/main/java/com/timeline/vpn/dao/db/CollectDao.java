package com.timeline.vpn.dao.db;

import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.CollectPo;
import org.apache.ibatis.annotations.Mapper;

/**
 * @author gqli
 * @date 2016年12月14日 下午12:32:29
 * @version V1.0
 */
@Mapper
public interface CollectDao extends BaseDBDao<CollectPo> {
    public void add(CollectPo po);
}

