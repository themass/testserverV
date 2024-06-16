package com.timeline.vpn.service.impl.handle.reg;

import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.po.UserPo;
import org.springframework.stereotype.Component;

/**
 * @Description: 5-10; vip3 15天
 * @author gqli
 * @date 2018年7月31日 下午4:25:18
 * @version V1.0
 */
@Component
public class UserRegDefHandler extends BaseUserRegHandle {

  @Override
  public boolean support(Integer t) {
    return false;
  }
  @Override
  public boolean isDefault() {
    return true;
  }
  @Override
  public void handeRef(Integer count, UserPo ref,BaseQuery baseQuery) {
  }

}

