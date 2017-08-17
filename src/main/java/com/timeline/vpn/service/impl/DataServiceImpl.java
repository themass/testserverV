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
import com.timeline.vpn.dao.db.IWannaDao;
import com.timeline.vpn.dao.db.RecommendDao;
import com.timeline.vpn.dao.db.SoundChannelDao;
import com.timeline.vpn.dao.db.VersionDao;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.PageBaseParam;
import com.timeline.vpn.model.po.AppVersion;
import com.timeline.vpn.model.po.IWannaPo;
import com.timeline.vpn.model.po.RecommendPo;
import com.timeline.vpn.model.po.SoundChannel;
import com.timeline.vpn.model.po.SoundItems;
import com.timeline.vpn.model.vo.IWannaVo;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.RecommendVo;
import com.timeline.vpn.model.vo.SoundChannelVo;
import com.timeline.vpn.model.vo.SoundItemsVo;
import com.timeline.vpn.model.vo.StateUseVo;
import com.timeline.vpn.model.vo.VersionInfoVo;
import com.timeline.vpn.model.vo.VoBuilder;
import com.timeline.vpn.model.vo.VoBuilder.BuildAction;
import com.timeline.vpn.service.DataService;
import com.timeline.vpn.service.UserService;

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
    private RecommendDao recommendDao;
    @Autowired
    private IWannaDao iWannaDao;
    @Autowired
    private UserService userService;
    @Autowired
    private SoundChannelDao soundChannelDao;
    @Override
    public InfoListVo<RecommendVo> getRecommendPage(BaseQuery baseQuery, PageBaseParam param) {
        //未登录   ， 登录，  VIP
        int type = baseQuery.getUser()==null?Constant.RecommendType.TYPE_OTHER:
            (baseQuery.getUser().getLevel()==Constant.UserLevel.LEVEL_FREE?Constant.RecommendType.TYPE_REG:Constant.RecommendType.TYPE_VIP);
        PageHelper.startPage(param.getStart(), param.getLimit());
        List<RecommendPo> poList = recommendDao.getPage(type);
        return VoBuilder.buildPageInfoVo((Page<RecommendPo>) poList, RecommendVo.class,null);
    }

    @Override
    public InfoListVo<RecommendVo> getRecommendVipPage( final BaseQuery baseQuery, PageBaseParam param) {
//        if(baseQuery.getUser()==null||baseQuery.getUser().getLevel()!=Constant.UserLevel.LEVEL_VIP){
//            throw new DataException(Constant.ResultMsg.RESULT_PERM_ERROR);
//        }
        PageHelper.startPage(param.getStart(), param.getLimit());
        List<RecommendPo> poList = recommendDao.getVipPage();
        return VoBuilder.buildPageInfoVo((Page<RecommendPo>) poList, RecommendVo.class,new BuildAction<RecommendPo,RecommendVo>(){

            @Override
            public void action(RecommendPo i, RecommendVo t) {
                if(baseQuery.getAppInfo().getVersion().compareTo("001000002000")<=0){
                    if(!StringUtils.isEmpty(t.getImg()) &&t.getImg().contains("pigu")){
                        t.setImg(null);
                    }
                }
            }
            
        });
    }

    @Override
    public VersionInfoVo getVersion(BaseQuery baseQuery,String platform,String channel) {
        VersionInfoVo vo = VoBuilder.buildVo(versionDao.getLast(platform,channel), VersionInfoVo.class,null);
        vo.setAdsShow(false);
        vo.setLogUp(true);
        if(!channel.equals("VPN")){
            AppVersion vpnVer = versionDao.getLast(platform,"VPN");
            vo.setVpnUrl(vpnVer.getUrl());
        }
        if(baseQuery!=null){
            String userName = baseQuery.getUser()==null?null:baseQuery.getUser().getName();
            userService.updateDevUseinfo(baseQuery.getAppInfo(),userName);
            if(channel.equals("VPN")){
                if(baseQuery.getUser()!=null){
                    StateUseVo state = userService.stateUse(Arrays.asList(baseQuery.getUser().getName(),baseQuery.getAppInfo().getDevId()));
                    vo.setStateUse(state);    
                }else{
                    StateUseVo state = userService.stateUse(Arrays.asList(baseQuery.getAppInfo().getDevId()));
                    vo.setStateUse(state);    
                }
            }
        }
       
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
        List<RecommendPo> poList = recommendDao.getRecoPage();
        return VoBuilder.buildPageInfoVo((Page<RecommendPo>) poList, RecommendVo.class,null);
    }

    @Override
    public InfoListVo<SoundChannelVo> getAllSoundChannel(BaseQuery baseQuery, PageBaseParam param) {
        PageHelper.startPage(param.getStart(), param.getLimit());
        List<SoundChannel> poList = soundChannelDao.getAll();
        return VoBuilder.buildPageInfoVo((Page<SoundChannel>) poList, SoundChannelVo.class,null);
    }

    @Override
    public InfoListVo<SoundItemsVo> getSoundItems(BaseQuery baseQuery,PageBaseParam param,String channel) {
        PageHelper.startPage(param.getStart(), param.getLimit());
        List<SoundItems> poList = soundChannelDao.getByChannel(channel);
        return VoBuilder.buildPageInfoVo((Page<SoundItems>) poList, SoundItemsVo.class,null);
    }

}

