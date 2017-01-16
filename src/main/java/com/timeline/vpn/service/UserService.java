package com.timeline.vpn.service;

import com.timeline.vpn.model.form.UserRegForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.DevApp;
import com.timeline.vpn.model.po.DevUseinfoPo;
import com.timeline.vpn.model.vo.RegCodeVo;
import com.timeline.vpn.model.vo.UserVo;

/**
 * @author gqli
 * @date 2016年3月10日 上午10:30:25
 * @version V1.0
 */
public interface UserService {
    public UserVo login(BaseQuery baseQuery, String name, String pwd);

    public void logout(BaseQuery baseQuery);

    public void reg(UserRegForm form, DevApp appInfo);

    public UserVo score(BaseQuery baseQuery, int score);

    public UserVo info(BaseQuery baseQuery);
    public RegCodeVo getRegCode(String channel); 
    public DevUseinfoPo updateDevUseinfo(DevApp appInfo,String userName);
}

