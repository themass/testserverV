package com.timeline.vpn.service;

import com.timeline.vpn.model.form.UserRegForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.DevApp;
import com.timeline.vpn.model.vo.UserVo;

/**
 * @author gqli
 * @date 2016年3月10日 上午10:30:25
 * @version V1.0
 */
public interface UserService {
    public void updateFreeUseinfo(BaseQuery baseQuery, long useTime);

    public UserVo login(BaseQuery baseQuery, String name, String pwd);

    public void logout(BaseQuery baseQuery);

    public void reg(UserRegForm form, DevApp appInfo);

    public UserVo score(BaseQuery baseQuery, int score);

    public UserVo info(BaseQuery baseQuery);
}

