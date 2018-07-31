package com.timeline.vpn.service;

import java.util.List;

import com.timeline.vpn.model.form.CustomeAddForm;
import com.timeline.vpn.model.form.UserEmailForm;
import com.timeline.vpn.model.form.UserRegForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.DevApp;
import com.timeline.vpn.model.param.PageBaseParam;
import com.timeline.vpn.model.po.DevUseinfoPo;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.RecommendVo;
import com.timeline.vpn.model.vo.RegCodeVo;
import com.timeline.vpn.model.vo.StateUseVo;
import com.timeline.vpn.model.vo.UserVo;

/**
 * @author gqli
 * @date 2016年3月10日 上午10:30:25
 * @version V1.0
 */
public interface UserService {
    public UserVo login(BaseQuery baseQuery, String name, String pwd,Integer score);

    public void logout(BaseQuery baseQuery);

    public void reg(UserRegForm form, BaseQuery baseQuery);
    public void updateEmail(UserEmailForm form, BaseQuery baseQuery);

    public UserVo score(BaseQuery baseQuery, int score);

    public UserVo info(BaseQuery baseQuery);
    public RegCodeVo getRegCode(String channel); 
    public DevUseinfoPo updateDevUseinfo(DevApp appInfo,String userName);

    public StateUseVo stateUse(List<String> name);

    public void addOrUpdateCustome(BaseQuery baseQuery, CustomeAddForm form);

    public void delCustome(BaseQuery baseQuery, int id);
    public InfoListVo<RecommendVo> getRecommendCustomePage(BaseQuery baseQuery, PageBaseParam param);
}

