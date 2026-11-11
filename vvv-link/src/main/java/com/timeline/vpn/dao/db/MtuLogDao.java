package com.timeline.vpn.dao.db;

import com.timeline.vpn.model.po.MtuLogPo;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
public interface MtuLogDao {
    void insertAll(List<MtuLogPo> list);
}
