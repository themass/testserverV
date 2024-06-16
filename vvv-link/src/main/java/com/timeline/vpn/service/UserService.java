package com.timeline.vpn.service;

import com.timeline.vpn.model.form.CustomeAddForm;
import com.timeline.vpn.model.form.UserEmailForm;
import com.timeline.vpn.model.form.UserRegForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.DevApp;
import com.timeline.vpn.model.param.PageBaseParam;
import com.timeline.vpn.model.vo.*;

import java.util.List;

/**
 * @author gqli
 * @date 2016年3月10日 上午10:30:25
 * @version V1.0
 */
public interface UserService {
    public UserVo login(BaseQuery baseQuery, String name, String pwd,Integer score);

    public void logout(BaseQuery baseQuery);
    public void del(BaseQuery baseQuery, String name, String pwd);
    public void reg(UserRegForm form, BaseQuery baseQuery);
    public void updateEmail(UserEmailForm form, BaseQuery baseQuery);

    public UserVo score(BaseQuery baseQuery, int score);

    public UserVo info(BaseQuery baseQuery);
    public RegCodeVo getRegCode(String channel); 
    public void updateDevUseinfo(DevApp appInfo,String userName);

    public StateUseVo stateUse(List<String> name);

    public void addOrUpdateCustome(BaseQuery baseQuery, CustomeAddForm form);

    public void delCustome(BaseQuery baseQuery, int id);
    public InfoListVo<RecommendVo> getRecommendCustomePage(BaseQuery baseQuery, PageBaseParam param);
    public InfoListVo<RecommendVo> getRecommendLocal(BaseQuery baseQuery, PageBaseParam param);
}

