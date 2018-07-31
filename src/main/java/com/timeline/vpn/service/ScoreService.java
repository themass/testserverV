package com.timeline.vpn.service;
/**
 * @Title: ScoreService.java
 * @Package com.timeline.vpn.service.impl
 * @Description: TODO(添加描述)
 * @author gqli
 * @date 2018年7月31日 下午5:10:25
 * @version V1.0
 */

import com.timeline.vpn.model.po.UserPo;

public interface ScoreService {
  public UserPo updateScore(String name);
}

