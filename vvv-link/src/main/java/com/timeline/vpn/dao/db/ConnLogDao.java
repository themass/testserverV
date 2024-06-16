package com.timeline.vpn.dao.db;

import com.timeline.vpn.model.po.ConnLogPo;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * @author gqli
 * @date 2018年8月3日 下午2:39:12
 * @version V1.0
 */
@Mapper
public interface ConnLogDao {
  public void insertAll(List<ConnLogPo> list);
}

