package com.timeline.vpn.service.impl;

import java.util.Arrays;
import java.util.Date;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import com.github.pagehelper.Page;
import com.github.pagehelper.PageHelper;
import com.timeline.vpn.Constant;
import com.timeline.vpn.VoBuilder;
import com.timeline.vpn.VoBuilder.BuildAction;
import com.timeline.vpn.dao.db.AppInfoDao;
import com.timeline.vpn.dao.db.IWannaDao;
import com.timeline.vpn.dao.db.VersionDao;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.PageBaseParam;
import com.timeline.vpn.model.po.AppInfoPo;
import com.timeline.vpn.model.po.AppVersion;
import com.timeline.vpn.model.po.IWannaPo;
import com.timeline.vpn.model.po.RecommendPo;
import com.timeline.vpn.model.vo.AppInfoVo;
import com.timeline.vpn.model.vo.IWannaVo;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.RecommendVo;
import com.timeline.vpn.model.vo.StateUseVo;
import com.timeline.vpn.model.vo.VersionInfoVo;
import com.timeline.vpn.model.vo.VipDescVo;
import com.timeline.vpn.service.DataService;
import com.timeline.vpn.service.DataVideoService;
import com.timeline.vpn.service.UserService;
import com.timeline.vpn.service.impl.recommend.RecommendServiceProxy;

/**
 * @author gqli
 * @date 2016年3月10日 下午4:45:36
 * @version V1.0
 */
@Service
public class DataServiceImpl implements DataService {

    @Autowired
    private VersionDao versionDao;
    @Autowired
    private RecommendServiceProxy recommendServiceProxy;
    @Autowired
    private IWannaDao iWannaDao;
    @Autowired
    private UserService userService;
    @Autowired
    private AppInfoDao appInfoDao;
    @Autowired
    private DataVideoService dataVideoService;
    @Override
    public InfoListVo<RecommendVo> getRecommendPage(BaseQuery baseQuery, PageBaseParam param) {
        //未登录   ， 登录，  VIP
        final String baseUrl = CdnChooseUtil.getImageBaseUrl(baseQuery.getAppInfo().getUserIp());
        int type = baseQuery.getUser()==null?Constant.RecommendType.TYPE_OTHER:
            (baseQuery.getUser().getLevel()==Constant.UserLevel.LEVEL_FREE?Constant.RecommendType.TYPE_REG:Constant.RecommendType.TYPE_VIP);
        PageHelper.startPage(param.getStart(), param.getLimit());
        List<RecommendPo> poList = recommendServiceProxy.getPage(type);
        return VoBuilder.buildPageInfoVo((Page<RecommendPo>) poList, RecommendVo.class,new BuildAction<RecommendPo,RecommendVo>(){

            @Override
            public void action(RecommendPo i, RecommendVo t) {
                if(!StringUtils.isEmpty(baseUrl) && !StringUtils.isEmpty(i.getImg())){
                    t.setImg(baseUrl+i.getImg());
                }
            }
            
        });
    }
    @Override
    public InfoListVo<RecommendVo> getRecommendMoviePage(BaseQuery baseQuery) {
        return dataVideoService.getVideoChannel(baseQuery,Constant.MOVIE_TYPE);
    }

    @Override
    public InfoListVo<RecommendVo> getRecommendNightPage(BaseQuery baseQuery, PageBaseParam param) {
        return getRecommendVipPage(baseQuery,param);
    }

    @Override
    public InfoListVo<RecommendVo> getRecommendAreaPage(BaseQuery baseQuery, PageBaseParam param) {
        final String baseUrl = CdnChooseUtil.getImageBaseUrl(baseQuery.getAppInfo().getUserIp());
        PageHelper.startPage(param.getStart(), param.getLimit());
        List<RecommendPo> poList = recommendServiceProxy.getAreaPage();
        return VoBuilder.buildPageInfoVo((Page<RecommendPo>) poList, RecommendVo.class,new BuildAction<RecommendPo,RecommendVo>(){

            @Override
            public void action(RecommendPo i, RecommendVo t) {
                if(!StringUtils.isEmpty(baseUrl) && !StringUtils.isEmpty(i.getImg())){
                    t.setImg(baseUrl+i.getImg());
                }
            }
            
        });
    }
    @Override
    public InfoListVo<RecommendVo> getRecommendVipPage( final BaseQuery baseQuery, PageBaseParam param) {
        final String baseUrl = CdnChooseUtil.getImageBaseUrl(baseQuery.getAppInfo().getUserIp());
        PageHelper.startPage(param.getStart(), param.getLimit());
        List<RecommendPo> poList = recommendServiceProxy.getVipPage();
        return VoBuilder.buildPageInfoVo((Page<RecommendPo>) poList, RecommendVo.class,new BuildAction<RecommendPo,RecommendVo>(){

            @Override
            public void action(RecommendPo i, RecommendVo t) {
                if(!StringUtils.isEmpty(baseUrl) && !StringUtils.isEmpty(i.getImg())){
                    t.setImg(baseUrl+i.getImg());
                }
            }
            
        });
    }

    @Override
    public VersionInfoVo getVersion(BaseQuery baseQuery,String platform,String channel) {
        VersionInfoVo vo = VoBuilder.buildVo(versionDao.getLast(platform,channel), VersionInfoVo.class,null);
        vo.setAdsShow(false);
        vo.setLogUp(true);
        if(!Constant.VPN.equals(channel)){
            AppVersion vpnVer = versionDao.getLast(platform,Constant.VPN);
            vo.setVpnUrl(vpnVer.getUrl());
        }
        if(baseQuery!=null){
            String userName = baseQuery.getUser()==null?null:baseQuery.getUser().getName();
            userService.updateDevUseinfo(baseQuery.getAppInfo(),userName);
            if(Constant.VPN.equals(channel)){
                if(baseQuery.getUser()!=null){
                    StateUseVo state = userService.stateUse(Arrays.asList(baseQuery.getUser().getName(),baseQuery.getAppInfo().getDevId()));
                    vo.setStateUse(state);    
                }else{
                    StateUseVo state = userService.stateUse(Arrays.asList(baseQuery.getAppInfo().getDevId()));
                    vo.setStateUse(state);    
                }
            }
        }
        VipDescVo desc = new VipDescVo();
        desc.setDesc("每周扣除100积分，VIP状态随积分变动");
        desc.setDesc1("1500积分=VIP1；3000积分=VIP2；点击广告赚积分");
        if(baseQuery!=null&&baseQuery.getUser()!=null)
            desc.setScore(baseQuery.getUser().getScore());
        vo.setVitamioExt(Constant.VIDEO_EXT);
        vo.setVipDesc(desc);
        return vo;
    }

    @Override
    public InfoListVo<IWannaVo> getIwannaPage(BaseQuery baseQuery, PageBaseParam param) {
        PageHelper.startPage(param.getStart(), param.getLimit());
        Page<IWannaPo> data = (Page<IWannaPo>) iWannaDao.getPage();
        return VoBuilder.buildIWannaPageInfoVo(data, baseQuery);
    }

    @Override
    public IWannaVo addIwanna(BaseQuery baseQuery, String content) {
        IWannaPo po = new IWannaPo();
        po.setContent(content);
        po.setCreateTime(new Date());
        po.setLikes(0);
        po.setLikeUsers(Constant.superMan);
        po.setName(baseQuery.getUser().getName());
        po.setIp(baseQuery.getAppInfo().getUserIp());
        po.setAppName(baseQuery.getAppInfo().getChannel());
        iWannaDao.insert(po);
        return VoBuilder.buildIWannaVo(po, baseQuery.getUser().getName());
    }

    @Override
    public void addIwannaLike(BaseQuery baseQuery, long id) {
        IWannaPo po = iWannaDao.get(id);
        po.setLikes(po.getLikes() + 1);
        if (baseQuery.getUser()!=null && !po.getLikeUsers().contains(baseQuery.getUser().getName())) {
            po.setLikeUsers(po.getLikeUsers() + "," + baseQuery.getUser().getName());
        }
        iWannaDao.like(po);

    }

    @Override
    public InfoListVo<RecommendVo> getRecommendRecPage(BaseQuery baseQuery, PageBaseParam param) {
        PageHelper.startPage(param.getStart(), param.getLimit());
        List<RecommendPo> poList = recommendServiceProxy.getRecoPage();
        return VoBuilder.buildPageInfoVo((Page<RecommendPo>) poList, RecommendVo.class,null);
    }

    @Override
    public InfoListVo<AppInfoVo> getAllApp(BaseQuery baseQuery) {
        List<AppInfoPo> list = appInfoDao.getAll();
        return VoBuilder.buildListInfoVo(list, AppInfoVo.class,null);
    }
    @Override
    public InfoListVo<AppInfoVo> getAllDon(BaseQuery baseQuery) {
        List<AppInfoPo> list = appInfoDao.getAllDon();
        return VoBuilder.buildListInfoVo(list, AppInfoVo.class,null);
    }

    

}

