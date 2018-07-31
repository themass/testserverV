package com.timeline.vpn.service.impl.handle.reg;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.po.UserPo;

/**
 * @Description: 5-10; vip3 15天
 * @author gqli
 * @date 2018年7月31日 下午4:25:18
 * @version V1.0
 */
@Component
public class UserReg15Handler extends BaseUserRegHandle {
  @Override
  public boolean support(Integer t) {
    return t==15;
  }

  @Override
  public void handeRef(Integer count, UserPo ref,BaseQuery baseQuery) {
      handleUserVip3(ref,50);
      String content = "@"+ref.getName()+" 恭喜你,获得VIP3-50天使用权，免费赠送你PC使用权30天/100G, 快联系管理员领取吧！";
      dataService.addIwannaScore(baseQuery, content);
  }

}

