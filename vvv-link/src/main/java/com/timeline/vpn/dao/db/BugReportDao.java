package com.timeline.vpn.dao.db;

import com.timeline.vpn.model.po.BugReportPo;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface BugReportDao {
    void insert(BugReportPo po);
}
