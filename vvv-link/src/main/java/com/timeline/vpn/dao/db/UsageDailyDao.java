package com.timeline.vpn.dao.db;

import com.timeline.vpn.model.po.UsageDailyPo;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
public interface UsageDailyDao {
    /** 按 (devId, day) 覆盖写入：客户端可以重复上报最近几天而不产生重复行。 */
    void upsertAll(List<UsageDailyPo> list);
}
