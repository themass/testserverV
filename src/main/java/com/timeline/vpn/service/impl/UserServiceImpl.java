package com.timeline.vpn.service.impl;

import java.util.Date;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.timeline.vpn.Constant;
import com.timeline.vpn.dao.db.DevUseinfoDao;
import com.timeline.vpn.dao.db.UserDao;
import com.timeline.vpn.exception.DataException;
import com.timeline.vpn.exception.LoginException;
import com.timeline.vpn.model.form.UserRegForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.DevApp;
import com.timeline.vpn.model.po.DevUseinfoPo;
import com.timeline.vpn.model.po.UserPo;
import com.timeline.vpn.model.vo.RegCodeVo;
import com.timeline.vpn.model.vo.UserVo;
import com.timeline.vpn.model.vo.VoBuilder;
import com.timeline.vpn.service.CacheService;
import com.timeline.vpn.service.RadUserCheckService;
import com.timeline.vpn.service.RegAuthService;
import com.timeline.vpn.service.UserService;

/**
 * @author gqli
 * @date 2016年3月10日 上午10:31:36
 * @version V1.0
 */
@Service
public class UserServiceImpl implements UserService {
    @Autowired
    private DevUseinfoDao devInfoDao;
    @Autowired
    private UserDao userDao;
    @Autowired
    private RadUserCheckService checkService;
    @Autowired
    private CacheService cacheService;
    @Autowired
    private RegAuthService regAuthService;

    private DevUseinfoPo updateDevUseinfo(DevApp appInfo) {
        DevUseinfoPo po = devInfoDao.get(appInfo.getDevId());
        if(po==null){
            po = new DevUseinfoPo();
            po.setCreatTime(new Date());
            po.setDevId(appInfo.getDevId());
            po.setLastUpdate(new Date());
            po.setPlatform(appInfo.getPlatform());
            po.setVersion(appInfo.getVersion());
            devInfoDao.replace(po);
        }else{
            po.setDevId(appInfo.getDevId());
            po.setLastUpdate(new Date());
            po.setPlatform(appInfo.getPlatform());
            po.setVersion(appInfo.getVersion());
            devInfoDao.update(po);
        }
        return po;
    }

    @Override
    public UserVo login(BaseQuery baseQuery, String name, String pwd) {
        UserPo po = userDao.get(name, pwd);
        if (po != null) {
            updateDevUseinfo(baseQuery.getAppInfo());
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
    @Transactional
    public void reg(UserRegForm form, DevApp appInfo) {
        if (form.getPwd().equals(form.getRePwd())) {
//            String code = cacheService.get(form.getChannel());
//            if(!form.getCode().equals(code)){
//                throw new RegCodeException(Constant.ResultMsg.RESULT_REG_REGCODE);
//            }
            UserPo po = userDao.exist(form.getName());
            if (po == null) {
                po = new UserPo();
                po.setTime(new Date())
                        .setLevel(Constant.UserLevel.LEVEL_FREE).setName(form.getName())
                        .setPwd(form.getPwd()).setSex(form.getSex());
                userDao.insert(po);
                checkService.addRadUser(form.getName(), form.getPwd(), Constant.UserGroup.RAD_GROUP_REG);
                
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

    @Override
    public RegCodeVo getRegCode(String channel) {
        String code = regAuthService.reg(channel);
        RegCodeVo vo = new RegCodeVo();
        vo.setCode(code);
        return vo;
    }

}

