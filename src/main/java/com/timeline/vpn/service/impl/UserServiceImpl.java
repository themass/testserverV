package com.timeline.vpn.service.impl;

import java.util.Date;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.timeline.vpn.Constant;
import com.timeline.vpn.dao.db.FreeUseinfoDao;
import com.timeline.vpn.dao.db.UserDao;
import com.timeline.vpn.exception.DataException;
import com.timeline.vpn.exception.LoginException;
import com.timeline.vpn.model.form.UserRegForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.DevApp;
import com.timeline.vpn.model.po.FreeUseinfoPo;
import com.timeline.vpn.model.po.UserPo;
import com.timeline.vpn.model.vo.UserVo;
import com.timeline.vpn.model.vo.VoBuilder;
import com.timeline.vpn.service.CacheService;
import com.timeline.vpn.service.UserService;

/**
 * @author gqli
 * @date 2016年3月10日 上午10:31:36
 * @version V1.0
 */
@Service
public class UserServiceImpl implements UserService {
    @Autowired
    private FreeUseinfoDao pushSettingDao;
    @Autowired
    private UserDao userDao;
    @Autowired
    private CacheService cacheService;

    @Override
    public void updateFreeUseinfo(BaseQuery baseQuery, long useTime) {
        addOrUpdateFreeUseinfo(baseQuery.getAppInfo(), useTime);
    }

    private FreeUseinfoPo addOrUpdateFreeUseinfo(DevApp appInfo, long useTime) {
        FreeUseinfoPo po = pushSettingDao.get(appInfo.getDevId());
        if (po == null) {
            po = new FreeUseinfoPo();
            po.setCreatTime(new Date());
            po.setDevId(appInfo.getDevId());
            po.setLastUpdate(new Date());
            po.setPlatform(appInfo.getPlatform());
            po.setVersion(appInfo.getVersion());
            po.setUseTime(0l);
            pushSettingDao.insert(po);
        } else {
            po.setLastUpdate(new Date());
            po.setVersion(appInfo.getVersion());
            po.setPlatform(appInfo.getPlatform());
            po.setUseTime(po.getUseTime() + useTime);
            pushSettingDao.update(po);
        }
        return po;
    }

    @Override
    public UserVo login(BaseQuery baseQuery, String name, String pwd) {
        UserPo po = userDao.get(name, pwd);
        if (po != null) {
            updateFreeUseinfo(baseQuery, 0l);
            String token = cacheService.putUser(po);
            UserVo vo = VoBuilder.buildVo(po, UserVo.class);
            vo.setToken(token);
            return vo;
        } else {
            throw new LoginException(Constant.ResultMsg.RESULT_PWD_ERROR);
        }
    }

    @Override
    public void logout(BaseQuery baseQuery) {
        cacheService.del(baseQuery.getToken());
    }

    @Override
    public void reg(UserRegForm form, DevApp appInfo) {
        if (form.getPwd().equals(form.getRePwd())) {
            UserPo po = userDao.exist(form.getName());
            if (po == null) {
                po = new UserPo();
                po.setDevId(appInfo.getDevId()).setTime(new Date())
                        .setLevel(Constant.UserLevel.LEVEL_FREE).setName(form.getName())
                        .setPwd(form.getPwd()).setUseCount(0).setSex(form.getSex());
                userDao.insert(po);
            } else {
                throw new DataException(Constant.ResultMsg.RESULT_EXIST_ERROR);
            }
        } else {
            throw new DataException(Constant.ResultMsg.RESULT_DATA_ERROR);
        }
    }

    @Override
    public UserVo score(BaseQuery baseQuery, int score) {
        userDao.score(score, baseQuery.getUser().getName());
        UserPo po = userDao.exist(baseQuery.getUser().getName());
        UserVo vo = VoBuilder.buildVo(po, UserVo.class);
        vo.setToken(baseQuery.getToken());
        return vo;
    }

    @Override
    public UserVo info(BaseQuery baseQuery) {
        UserPo po = userDao.exist(baseQuery.getUser().getName());
        UserVo vo = VoBuilder.buildVo(po, UserVo.class);
        cacheService.del(baseQuery.getToken());
        String token = cacheService.putUser(po);
        vo.setToken(token);
        return vo;
    }

}

