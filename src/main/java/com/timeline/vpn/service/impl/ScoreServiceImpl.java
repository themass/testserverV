package com.timeline.vpn.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import com.sun.tools.internal.jxc.ap.Const;
import com.timeline.vpn.Constant;
import com.timeline.vpn.dao.db.UserDao;
import com.timeline.vpn.model.po.UserPo;
import com.timeline.vpn.service.RadUserCheckService;
import com.timeline.vpn.service.ScoreService;
import com.timeline.vpn.util.ScoreCalculate;

/**
 * @author gqli
 * @date 2018年7月31日 下午5:13:01
 * @version V1.0
 */
@Component
public class ScoreServiceImpl implements ScoreService{
  @Autowired
  private UserDao userDao;
  @Autowired 
  private RadUserCheckService checkService;
  @Override
  public UserPo updateScore(String name) {
    UserPo po = userDao.exist(name);
    if(po!=null) {
      po.setLevel(ScoreCalculate.level(po.getLevel(),po.getScore()));
      userDao.updateLevel(po);
      checkService.updateRadUserGroup(po.getName(), ScoreCalculate.group(po.getLevel()));
    }else {
      po = userDao.exist(Constant.ADMIN_NAME);
    }
    return po;
  }

}

