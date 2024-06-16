package vpn.service.impl.handle.reg;

import com.timeline.vpn.dao.db.UserDao;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.po.UserPo;
import com.timeline.vpn.service.DataService;
import com.timeline.vpn.service.strategy.BaseSupportHandle;
import com.timeline.vpn.util.DateTimeUtils;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.Date;

/**
 * @author gqli
 * @date 2017年11月28日 下午6:32:52
 * @version V1.0
 */
public abstract class BaseUserRegHandle implements BaseSupportHandle<Integer>{
      @Autowired
      private UserDao userDao;
      @Autowired
      protected DataService dataService;
      public abstract void handeRef(Integer count, UserPo ref,BaseQuery baseQuery);
      @Override
      public boolean isDefault() {
        return false;
      }
      protected void handleUserVip3(UserPo user, int day) {
        Date start =  DateTimeUtils.addDay(new Date(), -1);;
        Date end = null;
        if(user.getPaidEndTime()==null || user.getPaidEndTime().before(new Date())) {
          end = DateTimeUtils.addDay(new Date(), day);
        }else {
          end = DateTimeUtils.addDay(user.getPaidEndTime(), day);
        }
        user.setPaidStartTime(start);
        user.setPaidEndTime(end);
        user.setLevel(3);
//        userDao.updateToLevelPaid(start, end, user.getName());
      }

}

