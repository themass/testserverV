package com.timeline.vpn.service.impl;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import com.github.pagehelper.Page;
import com.github.pagehelper.PageHelper;
import com.timeline.vpn.VoBuilder;
import com.timeline.vpn.VoBuilder.BuildAction;
import com.timeline.vpn.dao.db.SoundChannelDao;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.PageBaseParam;
import com.timeline.vpn.model.po.SoundChannel;
import com.timeline.vpn.model.po.SoundItems;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.RecommendVo;
import com.timeline.vpn.model.vo.SoundItemsVo;
import com.timeline.vpn.service.DataSoundService;
import com.timeline.vpn.service.job.reload.ZhIpCache;

/**
 * @author gqli
 * @date 2016年3月10日 下午4:45:36
 * @version V1.0
 */
@Service
public class DataSoundServiceImpl implements DataSoundService {
    @Autowired
    private SoundChannelDao soundChannelDao;

    @Override
    public InfoListVo<RecommendVo> getAllSoundChannel(final BaseQuery baseQuery, PageBaseParam param) {
        PageHelper.startPage(param.getStart(), param.getLimit());
        List<SoundChannel> poList = soundChannelDao.getAll();
        return VoBuilder.buildPageInfoVo((Page<SoundChannel>) poList, RecommendVo.class,new VoBuilder.BuildAction<SoundChannel,RecommendVo>(){
            @Override
            public void action(SoundChannel i, RecommendVo t) {
                t.setActionUrl(i.getActionUrl());
                t.setTitle(i.getName());
                t.setImg(CdnChooseUtil.getFetchImageBaseUrl(baseQuery.getAppInfo().getUserIp(),i.getPic()));
                t.setAdsPopShow(true);
                t.setAdsShow(true);
//                t.setShowType(0);
                t.setParam(i.getUrl());
                if(i.getRate()==null){
                    t.setRate(1.1f);
                }else{
                    t.setRate(i.getRate());
                }
            }
        });
    }

    @Override
    public InfoListVo<SoundItemsVo> getSoundItems(final BaseQuery baseQuery,PageBaseParam param,String channel,String keywork) {
        PageHelper.startPage(param.getStart(), param.getLimit());
        List<SoundItems> poList = soundChannelDao.getByChannel(channel,keywork);
        return VoBuilder.buildPageInfoVo((Page<SoundItems>) poList, SoundItemsVo.class,new BuildAction<SoundItems,SoundItemsVo>(){
            public void action(SoundItems i, SoundItemsVo t){
                if(!StringUtils.isEmpty(i.getMyFile()) && ZhIpCache.isChinaIp(baseQuery.getAppInfo().getUserIp())){
                    t.setUrl(i.getMyFile());
                }
            }
        });
    }


}

