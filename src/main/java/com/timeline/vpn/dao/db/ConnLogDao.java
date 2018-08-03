package com.timeline.vpn.dao.db;

import java.util.List;

import com.timeline.vpn.model.po.ConnLogPo;

/**
 * @author gqli
 * @date 2018年8月3日 下午2:39:12
 * @version V1.0
 */
public interface ConnLogDao {
  public void insertAll(List<ConnLogPo> list);
}

