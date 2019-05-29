package com.timeline.vpn.service.impl;

import java.util.Arrays;
import java.util.Date;
import java.util.List;

import org.apache.commons.lang.math.RandomUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.CollectionUtils;
import org.springframework.util.StringUtils;

import com.github.pagehelper.Page;
import com.github.pagehelper.PageHelper;
import com.timeline.vpn.Constant;
import com.timeline.vpn.VoBuilder;
import com.timeline.vpn.dao.db.DevUseinfoDao;
import com.timeline.vpn.dao.db.RadacctDao;
import com.timeline.vpn.dao.db.UserDao;
import com.timeline.vpn.exception.DataException;
import com.timeline.vpn.exception.LoginException;
import com.timeline.vpn.model.form.CustomeAddForm;
import com.timeline.vpn.model.form.UserEmailForm;
import com.timeline.vpn.model.form.UserRegForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.DevApp;
import com.timeline.vpn.model.param.PageBaseParam;
import com.timeline.vpn.model.po.DevUseinfoPo;
import com.timeline.vpn.model.po.RadacctState;
import com.timeline.vpn.model.po.RecommendPo;
import com.timeline.vpn.model.po.UserPo;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.RecommendVo;
import com.timeline.vpn.model.vo.RegCodeVo;
import com.timeline.vpn.model.vo.StateUseVo;
import com.timeline.vpn.model.vo.UserVo;
import com.timeline.vpn.service.CacheService;
import com.timeline.vpn.service.RadUserCheckService;
import com.timeline.vpn.service.RegAuthService;
import com.timeline.vpn.service.ScoreService;
import com.timeline.vpn.service.UserService;
import com.timeline.vpn.service.impl.handle.recommend.RecommendServiceProxy;
import com.timeline.vpn.service.impl.handle.reg.UserRegContext;
import com.timeline.vpn.util.CommonUtil;
import com.timeline.vpn.util.DateTimeUtils;
import com.timeline.vpn.util.DeviceUtil;

/**
 * @author gqli
 * @date 2016年3月10日 上午10:31:36
 * @version V1.0
 */
@Service
public class UserServiceImpl implements UserService {
    private static final Logger LOGGER = LoggerFactory.getLogger(UserServiceImpl.class);

    @Autowired
    private DevUseinfoDao devInfoDao;
    @Autowired
    private UserDao userDao;
    @Autowired
    private RadUserCheckService checkService;
    @Autowired
    private ScoreService scoreService;
    @Autowired
    private CacheService cacheService;
    @Autowired
    private RegAuthService regAuthService;
    @Autowired
    private RadacctDao radacctDao;
    @Autowired
    private RecommendServiceProxy recommendServiceProxy;
    @Autowired
    private UserRegContext userRegContext;
    @Autowired
    private ThreadPoolTaskExecutor taskExecutor;
    public void updateDevUseinfo(final DevApp appInfo,final String userName) {
        taskExecutor.execute(new Runnable() {
            @Override
            public void run() {
                DevUseinfoPo po = devInfoDao.get(appInfo.getDevId());
                if(po==null){
                    po = new DevUseinfoPo(); 
                    po.setCreatTime(new Date());
                    po.setDevId(appInfo.getDevId());
                    po.setLastUpdate(new Date());
                    po.setPlatform(appInfo.getPlatform());
                    po.setVersion(appInfo.getVersion());
                    po.setUserName(userName);
                    po.setLongitude(appInfo.getLon());
                    po.setLatitude(appInfo.getLat());
                    if(!StringUtils.isEmpty(userName)) {
                        po.setuHist(userName+",");
                    }
                    po.setExt(appInfo.getUa().substring(0, Math.min(2000, appInfo.getUa().length())));
                    if(StringUtils.isEmpty(appInfo.getNetType())) {
                      po.setChannel(Constant.VPN);
                    }else {
                        po.setChannel(appInfo.getNetType());
                    }
                    po.setIp(appInfo.getUserIp());
                    devInfoDao.insert(po);
                }else{
                    po.setDevId(appInfo.getDevId());
                    po.setLastUpdate(new Date());
                    po.setPlatform(appInfo.getPlatform());
                    po.setVersion(appInfo.getVersion());
                    if(!StringUtils.isEmpty(userName)) {
                        po.setUserName(userName);
                        po.setuHist(po.getuHist().replace(userName+",", ""));
                        po.setuHist(po.getuHist()+userName+",");
//                        LOGGER.warn(userName+"->"+po.getuHist()+"->"+appInfo.getUa());
                    }
                    po.setLongitude(appInfo.getLon());
                    po.setLatitude(appInfo.getLat());
                    po.setExt(appInfo.getUa().substring(0, Math.min(2000, appInfo.getUa().length())));
                    po.setIp(appInfo.getUserIp());
                    devInfoDao.update(po);
                }
            }
        });
        
    }

    @Override
    public UserVo login(BaseQuery baseQuery, String name, String pwd,Integer score) {
        if(!CommonUtil.isNumAndEnglish(name)||!CommonUtil.isNumAndEnglish(pwd)){
            throw new LoginException(Constant.ResultMsg.RESULT_LOGIN_PATTER);
        }
//        LOGGER.info("[name="+name+"; devId="+baseQuery.getAppInfo().getDevId()+"; ua="+baseQuery.getAppInfo().getUa()+"]");
        if(Constant.user.contains(name)) {
//            LOGGER.error("账号滥用用户："+name);
            throw new LoginException(Constant.ResultMsg.RESULT_ERROR_USER);
        }
        UserPo po = userDao.get(name, pwd);
        baseQuery.setUser(po);
        String channel = baseQuery.getAppInfo().getChannel();
        if(baseQuery.getAppInfo().getChannel().startsWith(Constant.SEX)) {
            channel = Constant.VPN;
        }
        if (po != null) {
            updateDevUseinfo(baseQuery.getAppInfo(),po.getName());
            
            if(po.getLevel()<3 && !Constant.userNoCheck.contains(name)) {
                int devCount = devInfoDao.getCount(name);
                if(devCount>2) {
                    throw new LoginException(Constant.ResultMsg.RESULT_ERROR_USER);
                }
            }
            String token = cacheService.putUser(po);
            baseQuery.setToken(token);
//            if(score!=null&&score!=0){
//                UserVo tmp = score(baseQuery,score);
//                po.setScore(tmp.getScore());
//                po.setLevel(tmp.getLevel());
//            }
            UserVo vo = VoBuilder.buildVo(po, UserVo.class,null);
            StateUseVo state = stateUse(Arrays.asList(vo.getName(),baseQuery.getAppInfo().getDevId()));
            vo.setStateUse(state);
            vo.setToken(token);
            vo.setAreaMi(po.getPwd());
            if(po.getPaidEndTime()!=null) {
                vo.setPaidTime("->VIP"+po.getLevel()+"-"+DateTimeUtils.formatDate(DateTimeUtils.YYYY_MM_DD, po.getPaidEndTime()));
            }
            return vo;
        } else {
            LOGGER.error("登录密码错误："+name+"--"+pwd);
            throw new LoginException(Constant.ResultMsg.RESULT_PWD_ERROR);
        }
    }

    @Override
    public void logout(BaseQuery baseQuery) {
        cacheService.del(baseQuery.getToken());
    }

    @Override
    @Transactional
    public void reg(UserRegForm form, BaseQuery baseQuery) {
        if(!CommonUtil.isNumAndEnglish(form.getName())||!CommonUtil.isNumAndEnglish(form.getPwd())){
            throw new LoginException(Constant.ResultMsg.RESULT_LOGIN_PATTER);
        }
        if (form.getPwd().equals(form.getRePwd())) {
            UserPo po = userDao.exist(form.getName());
            if (po == null) {
                updateDevUseinfo(baseQuery.getAppInfo(),form.getName());
//                DevUseinfoPo info = devInfoDao.get(baseQuery.getAppInfo().getDevId());
//                if(info!=null && !StringUtils.isEmpty(info.getuHist()) && baseQuery.getAppInfo().getDevId().length()>22) {
//                    String[]len =info.getuHist().split(",");
//                    if(len.length>10) {
//                        LOGGER.error("垃圾用户，注册账号刷积分:"+info.getDevId());
//                        throw new LoginException(Constant.ResultMsg.RESULT_ERROR_MANYUSER);
//                    }
//                }
                po = new UserPo();
                po.setTime(new Date())
                        .setLevel(Constant.UserLevel.LEVEL_FREE).setName(form.getName())
                        .setPwd(form.getPwd()).setSex(form.getSex()).setEmail(form.getEmail());
                if(StringUtils.isEmpty(baseQuery.getAppInfo().getNetType())) {
                  po.setChannel(Constant.VPN);
                }else {
                    po.setChannel(baseQuery.getAppInfo().getNetType());
                    po.setLevel(Constant.UserLevel.LEVEL_FREE);
//                    po.setPaidStartTime(new Date());
//                    po.setPaidEndTime(DateTimeUtils.addDay(new Date(), 7));
                }
                po.setPaidStartTime(new Date());
                po.setPaidEndTime(new Date());
                userDao.insert(po);
                checkService.addRadUser(form.getName(), form.getPwd(), Constant.UserGroup.RAD_GROUP_REG);
                baseQuery.setUser(po);
                userRegContext.handleRef(baseQuery, form.getRef());
                
            } else {
                throw new LoginException(Constant.ResultMsg.RESULT_EXIST_ERROR);
            }
        } else {
            throw new DataException(Constant.ResultMsg.RESULT_DATA_ERROR);
        }
       
    }

    @Override
    public UserVo score(BaseQuery baseQuery, int score) {
        if(cacheService.updateCount(baseQuery.getUser())<2) {
            userDao.score(score, baseQuery.getUser().getName());
        }
        UserPo po = scoreService.updateScore(baseQuery.getUser().getName());
        cacheService.updateUser(baseQuery.getToken(),po);
        UserVo vo = VoBuilder.buildVo(po, UserVo.class,null);
        if(po.getPaidEndTime()!=null) {
            vo.setPaidTime("->VIP"+po.getLevel()+"-"+DateTimeUtils.formatDate(DateTimeUtils.YYYY_MM_DD, po.getPaidEndTime()));
        }
        vo.setToken(baseQuery.getToken());
        return vo;
    }
    @Override
    public StateUseVo stateUse(List<String> names){
        if(CollectionUtils.isEmpty(names)) {
            return VoBuilder.buildStateUseVo(null);
        }else {
            RadacctState ret = radacctDao.dateState(names);
            return VoBuilder.buildStateUseVo(ret);
        }
        
    }

    @Override
    public UserVo info(BaseQuery baseQuery) {
        UserPo po = userDao.exist(baseQuery.getUser().getName());
        UserVo vo = VoBuilder.buildVo(po, UserVo.class,null);
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

    @Override
    public void addOrUpdateCustome(BaseQuery baseQuery, CustomeAddForm form) {
        RecommendPo po = new RecommendPo();
        po.setTitle(form.getTitle());
        po.setActionUrl(form.getUrl());
        po.setId(form.getId());
        po.setName(baseQuery.getUser().getName());
        po.setCreateTime(new Date());
        po.setColor(Constant.colorBg.get(RandomUtils.nextInt() % Constant.colorBg.size()));
        recommendServiceProxy.replaceCustome(po);
    }

    @Override
    public void delCustome(BaseQuery baseQuery, int id) {
        recommendServiceProxy.delCustome(id);
    }

    @Override
    public InfoListVo<RecommendVo> getRecommendCustomePage(BaseQuery baseQuery, PageBaseParam param) {
        PageHelper.startPage(param.getStart(), param.getLimit());
        List<RecommendPo> poList ;
        if(DeviceUtil.isAdmin(baseQuery)) {
            poList = recommendServiceProxy.getCustomeAllPage();
        }else{
            poList = recommendServiceProxy.getCustomePage(baseQuery.getUser().getName());
        }
        for(int index=0;index<poList.size();index++){
            if(StringUtils.isEmpty(poList.get(index).getColor()))
                poList.get(index).setColor(Constant.colorBg.get(index % Constant.colorBg.size()));
        }
        return VoBuilder.buildPageInfoVo((Page<RecommendPo>) poList, RecommendVo.class,null);

    }

    @Override
    public void updateEmail(UserEmailForm form, BaseQuery baseQuery) {
        userDao.updateEmail(form.getEmail(), baseQuery.getUser().getName());
    }

}

