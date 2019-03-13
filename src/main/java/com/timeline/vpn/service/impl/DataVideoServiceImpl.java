package com.timeline.vpn.service.impl;

import java.util.List;

import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.github.pagehelper.Page;
import com.github.pagehelper.PageHelper;
import com.timeline.vpn.Constant;
import com.timeline.vpn.VoBuilder;
import com.timeline.vpn.dao.db.VideoDao;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.PageBaseParam;
import com.timeline.vpn.model.po.VideoChannelPo;
import com.timeline.vpn.model.po.VideoPo;
import com.timeline.vpn.model.po.VideoUserItemPo;
import com.timeline.vpn.model.po.VideoUserPo;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.RecommendVo;
import com.timeline.vpn.service.DataVideoService;

/**
 * @author gqli
 * @date 2016年3月10日 下午4:45:36
 * @version V1.0
 */
@Service
public class DataVideoServiceImpl implements DataVideoService {
    private static final Logger LOGGER =
            LoggerFactory.getLogger(DataVideoServiceImpl.class);
    @Autowired
    private VideoDao videoDao;
    @Override
    public InfoListVo<RecommendVo> getVideoPage(BaseQuery baseQuery, PageBaseParam param) {
        PageHelper.startPage(param.getStart(), param.getLimit());
        List<VideoPo> list = videoDao.getPage();
        return VoBuilder.buildPageInfoVo((Page<VideoPo>)list, RecommendVo.class,new VoBuilder.BuildAction<VideoPo,RecommendVo>(){
            @Override
            public void action(VideoPo i, RecommendVo t) {
                t.setActionUrl(i.getUrl()); 
                t.setTitle(i.getName());
                t.setImg(i.getPic());
                t.setAdsPopShow(false);
                t.setAdsShow(true); 
                t.setParam(i.getUrl());
                t.setDataType(Constant.dataType_VIDEO_CHANNEL);
            }
        });
    }

    @Override
    public InfoListVo<RecommendVo> getVideoChannel(BaseQuery baseQuery,String channel) {
        List<VideoChannelPo> list = videoDao.getChannel(channel);
        return VoBuilder.buildListInfoVo(list, RecommendVo.class,new VoBuilder.BuildAction<VideoChannelPo,RecommendVo>(){
            @Override
            public void action(VideoChannelPo i, RecommendVo t) {
                t.setActionUrl(i.getUrl());
                t.setTitle(i.getName());
                t.setImg(i.getPic());
                t.setAdsPopShow(false);
                t.setAdsShow(true);
                t.setParam(i.getChannel());
                t.setShowLogo(i.getCount()+"部");
                t.setDataType(Constant.dataType_VIDEO_CHANNEL);
                t.setChannelType(i.getChannelType());
            }
        });
    }

    @Override
    public InfoListVo<RecommendVo> getVideoChannelItemsPage(BaseQuery baseQuery,
            PageBaseParam param, String channel,String keywork,String channelOrg) {
        VideoChannelPo po = videoDao.getOneChannel(channelOrg);
        List<VideoPo> list = null;
        if(!StringUtils.isEmpty(channelOrg) && channelOrg.startsWith("one_")) {
            channel = channelOrg;
        }
        String channelType = po.getChannelType();
        String baseurl = null;
        //关键字检索-》使用baseurl来检索
        if(!StringUtils.isEmpty(keywork) && !StringUtils.isEmpty(po.getBaseurl())) {
            baseurl = po.getBaseurl();
            channel = null;
        }
        if(!StringUtils.isEmpty(keywork) && keywork.contains(Constant.line)) {
            //全局检索
            keywork = keywork.substring(0, keywork.indexOf(Constant.line));
            channel = null;
            channelType = null;
            baseurl = null;
        }else if(!StringUtils.isEmpty(keywork)&&"movie".equals(channelType)) {
            channel = null;
            channelType = "movie";
            baseurl = null;
        }
        
        
        if(baseQuery.getAppInfo().getNetType()!=null && baseQuery.getAppInfo().getNetType().contains(Constant.PLAYTYPE)) {
            channelType = "movie";
            baseurl = null;
            channel = null;
        }
        PageHelper.startPage(param.getStart(), param.getLimit());
        LOGGER.error(channel+"-"+keywork+"-"+channelType+"-"+baseurl);
        list = videoDao.getChannelItems(channel,keywork,channelType,baseurl); 
        return VoBuilder.buildPageInfoVo((Page<VideoPo>)list, RecommendVo.class,new VoBuilder.BuildAction<VideoPo,RecommendVo>(){
            @Override
            public void action(VideoPo i, RecommendVo t) {
                t.setActionUrl(i.getUrl());
                t.setTitle(i.getName());
                t.setImg(i.getPic());
                t.setAdsPopShow(false);
                t.setAdsShow(true);
                t.setParam(i.getBaseurl());
                t.setExtra(i.getVideoType());
                t.setDataType(Constant.dataType_VIDEO_CHANNEL);
            }
        });
    }

    @Override
    public InfoListVo<RecommendVo> getVideoUserPage(BaseQuery baseQuery, PageBaseParam param,String channel) {
        PageHelper.startPage(param.getStart(), param.getLimit());
        List<VideoUserPo> list = videoDao.getUsers(channel);
        return VoBuilder.buildPageInfoVo((Page<VideoUserPo>)list, RecommendVo.class,new VoBuilder.BuildAction<VideoUserPo,RecommendVo>(){
            @Override
            public void action(VideoUserPo i, RecommendVo t) {
                t.setActionUrl(i.getUserId());
                t.setTitle(i.getName());
                t.setImg(i.getPic());
                t.setAdsPopShow(false);
                t.setAdsShow(true);
                t.setParam(i.getChannel());
                t.setShowLogo(i.getCount()+"大类");
                t.setDataType(Constant.dataType_VIDEO_CHANNEL);
                t.setChannelType(i.getChannelType());
            }
        });
    }

    @Override
    public InfoListVo<RecommendVo> getVideoUserItemsPage(BaseQuery baseQuery, PageBaseParam param,
            String userId,String keyword) {
        VideoUserPo po = videoDao.getUserByUserId(userId);
        PageHelper.startPage(param.getStart(), param.getLimit());
        String channel = po.getChannel();
        if(!StringUtils.isEmpty(keyword)) {
            userId = null;
            if(keyword.contains(Constant.line)) {
                keyword = keyword.substring(0, keyword.indexOf(Constant.line));
                userId = null;
                channel = null;
            }
        }
        
        List<VideoUserItemPo> list = videoDao.getUserItems(channel,userId,keyword);
        return VoBuilder.buildPageInfoVo((Page<VideoUserItemPo>)list, RecommendVo.class,new VoBuilder.BuildAction<VideoUserItemPo,RecommendVo>(){
            @Override
            public void action(VideoUserItemPo i, RecommendVo t) {
                t.setActionUrl(i.getUrl());
                t.setTitle(i.getName());
                t.setImg(i.getPic());
                t.setAdsPopShow(false);
                t.setAdsShow(true);
                t.setParam(i.getUserId());
                t.setExtra(i.getVideoType());
                t.setDataType(Constant.dataType_VIDEO_CHANNEL);
            }
        });
    }

    @Override
    public InfoListVo<RecommendVo> getVideoTvItemPage(BaseQuery baseQuery, PageBaseParam param,
            String channel) {
        PageHelper.startPage(param.getStart(), param.getLimit());
        Page<VideoPo>list = (Page<VideoPo>)videoDao.getTvItem(channel);
        return VoBuilder.buildPageInfoVo(list, RecommendVo.class,new VoBuilder.BuildAction<VideoPo,RecommendVo>(){
            @Override
            public void action(VideoPo i, RecommendVo t) {
                t.setActionUrl(i.getUrl());
                t.setTitle(i.getName());
                t.setImg(i.getPic());
                t.setAdsPopShow(false);
                t.setAdsShow(true);
                t.setParam(i.getBaseurl());
                t.setExtra(i.getVideoType());
                t.setDataType(Constant.dataType_VIDEO_CHANNEL);
            }
        });
    }

    @Override
    public InfoListVo<RecommendVo> getVideoTvChannelPage(BaseQuery baseQuery,  PageBaseParam param,String channelType,
            String keyword) {
        PageHelper.startPage(param.getStart(), param.getLimit());
        List<VideoChannelPo> list = videoDao.getTvChannel(channelType, keyword);
        return VoBuilder.buildPageInfoVo((Page<VideoChannelPo>)list, RecommendVo.class,new VoBuilder.BuildAction<VideoChannelPo,RecommendVo>(){
            @Override
            public void action(VideoChannelPo i, RecommendVo t) {
                t.setActionUrl(i.getUrl());
                t.setTitle(i.getName());
                t.setImg(i.getPic());
                t.setAdsPopShow(false);
                t.setAdsShow(true);
                t.setParam(i.getUrl());
                t.setShowLogo(i.getCount()+"集");
                t.setDataType(Constant.dataType_VIDEO_CHANNEL);
            }
        });
    }

}

