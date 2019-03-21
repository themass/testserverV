package com.timeline.vpn.service.impl.handle.reg;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import com.timeline.vpn.Constant;
import com.timeline.vpn.dao.db.DevUseinfoDao;
import com.timeline.vpn.dao.db.UserDao;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.po.DevUseinfoPo;
import com.timeline.vpn.model.po.UserPo;
import com.timeline.vpn.service.ScoreService;
import com.timeline.vpn.service.impl.DataServiceImpl;
import com.timeline.vpn.service.strategy.BaseSingleServiceContext;

/**
 * @author gqli
 * @date 2018年7月31日 下午5:01:15
 * @version V1.0
 */
@Component
public class UserRegContext extends BaseSingleServiceContext<Integer,BaseUserRegHandle> {
    private static final Logger LOGGER =
            LoggerFactory.getLogger(UserRegContext.class);
  @Autowired
  private DevUseinfoDao devInfoDao;
  @Autowired
  private UserDao userDao;
  @Autowired
  private ScoreService scoreService;
  public void handleRef(BaseQuery baseQuery,String ref) {
    if(!StringUtils.isEmpty(ref)) {
      DevUseinfoPo po = devInfoDao.get(baseQuery.getAppInfo().getDevId());
      if(po==null) {
          LOGGER.error("找不到用户的设备信息："+baseQuery.getAppInfo());
          return;
      }
      if(StringUtils.isEmpty(po.getRef())) { 
          devInfoDao.updateRef(po.getDevId(), ref);
          userDao.score(Constant.ADS_REF_SCORE, ref);
          UserPo user = scoreService.updateScore(ref);
          Integer count = devInfoDao.getRefCount(ref);
          getService(count).handeRef(count, user, baseQuery);
      }
    }
  }
}

