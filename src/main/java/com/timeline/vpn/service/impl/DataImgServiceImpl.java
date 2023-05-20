package com.timeline.vpn.service.impl;

import java.util.List;

import org.apache.commons.lang.math.RandomUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import com.github.pagehelper.Page;
import com.github.pagehelper.PageHelper;
import com.timeline.vpn.Constant;
import com.timeline.vpn.VoBuilder;
import com.timeline.vpn.dao.db.ImgChannelDao;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.PageBaseParam;
import com.timeline.vpn.model.po.ImgChannelPo;
import com.timeline.vpn.model.po.ImgItemsItemPo;
import com.timeline.vpn.model.po.ImgItemsPo;
import com.timeline.vpn.model.vo.ImgItemVo;
import com.timeline.vpn.model.vo.ImgItemsVo;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.RecommendVo;
import com.timeline.vpn.service.DataImgService;

/**
 * @author gqli
 * @date 2016年3月10日 下午4:45:36
 * @version V1.0
 */
@Service
public class DataImgServiceImpl implements DataImgService {

    @Autowired
    private ImgChannelDao imgChannelDao;

    @Override
    public InfoListVo<RecommendVo> getAllImgChannel(BaseQuery baseQuery, PageBaseParam param,String channel) {
        List<ImgChannelPo> list = imgChannelDao.getChannel(channel);
        return VoBuilder.buildListInfoVo(list, RecommendVo.class,new VoBuilder.BuildAction<ImgChannelPo,RecommendVo>(){
            @Override
            public void action(ImgChannelPo i, RecommendVo t) {
                t.setActionUrl(i.getUrl());
                t.setTitle(i.getName());
                if(!StringUtils.isEmpty(i.getPic()))
                  t.setImg(i.getPic().trim());
                t.setAdsPopShow(true);
                t.setAdsShow(true);
                if(i.getShowType()==null)
                    t.setShowType(0);
                t.setParam(i.getName());
                t.setDataType(Constant.dataType_IMG_CHANNEL);
            }
        });
    }

    @Override
    public InfoListVo<ImgItemsVo> getImgItems(BaseQuery baseQuery, PageBaseParam param,
            String channel,String keywork) {
        if(!StringUtils.isEmpty(keywork)) {
            channel = null;
        }
//        PageHelper.startPage(param.getStart(), param.getLimit());
        List<ImgItemsPo> poList = imgChannelDao.getByChannel(channel,keywork);
        return VoBuilder.buildPageInfoVo(poList, ImgItemsVo.class,new VoBuilder.BuildAction<ImgItemsPo,ImgItemsVo>(){

          @Override
          public void action(ImgItemsPo i, ImgItemsVo t) {
          }
          
        },param.getLimit());
    }
    @Override
    public InfoListVo<RecommendVo> getImgItemImgs(BaseQuery baseQuery, PageBaseParam param,
            String channel,String keywork) {
        if(!StringUtils.isEmpty(keywork)) {
            channel = null;
        }

//        PageHelper.startPage(param.getStart(), param.getLimit());
        List<ImgItemsPo> poList = imgChannelDao.getByChannel(channel,keywork);
        return VoBuilder.buildPageInfoVo(poList, RecommendVo.class,new VoBuilder.BuildAction<ImgItemsPo,RecommendVo>(){
            @Override
            public void action(ImgItemsPo i, RecommendVo t) {
                t.setActionUrl(i.getUrl());
                t.setTitle(i.getName());
                if(!StringUtils.isEmpty(i.getPic()))
                  t.setImg(i.getPic().trim());
                t.setAdsPopShow(false);
                t.setAdsShow(true);
//                t.setShowType(0);
//                t.setRate(1.2f);
                t.setShowLogo(i.getPics()+"张");
//                t.setDataType(Constant.dataType_IMG_CHANNEL);
            }
        },param.getLimit());
    }
    @Override
    public InfoListVo<ImgItemVo> getImgItem(final BaseQuery baseQuery, String url) {
        List<ImgItemsItemPo> list = imgChannelDao.getItem(url);
        return VoBuilder.buildListInfoVo(list, ImgItemVo.class,new VoBuilder.BuildAction<ImgItemsItemPo,ImgItemVo>(){
            @Override
            public void action(ImgItemsItemPo i, ImgItemVo t) {
                t.setOrigUrl(i.getPicUrl().trim());
                t.setRemoteUrl(i.getPicUrl().trim());
//                if(!StringUtils.isEmpty(i.getPicUrl()))
//                    if(i.getPicUrl().contains("eroti-cart")){
//                        t.setPicUrl("http://imghhh.secondary.space/file/eroti/"+i.getId()+".jpg");
//                        t.setOrigUrl("http://imghhh.secondary.space/file/eroti/"+i.getId()+".jpg");
//                    }else if(i.getPicUrl().contains("singlove.com")){
//                        t.setPicUrl("http://imghhh.secondary.space/file/hhh/"+i.getId()+".jpg");
//                        t.setOrigUrl("http://imghhh.secondary.space/file/hhh/"+i.getId()+".jpg");
//                    }
//                if(!StringUtils.isEmpty(i.getPicUrl()))
//                    if(i.getPicUrl().contains("eroti-cart")){
//                        t.setRemoteUrl("http://imghhh.secondary.space/file/eroti/"+i.getId()+".jpg");
//                    }else if(i.getPicUrl().contains("singlove.com")){
//                        t.setRemoteUrl("http://imghhh.secondary.space/file/hhh/"+i.getId()+".jpg");
//                    }
//                if(StringUtils.isEmpty(i.getOrigUrl())){
//                    t.setOrigUrl(i.getPicUrl());
//                    return;
//                }
//                
//                if(HostCheck.isMyHost(baseQuery.getAppInfo().getUserIp())){
//                    t.setOrigUrl(i.getOrigUrl());
//                }else if(ZhIpCache.isChinaIp(baseQuery.getAppInfo().getUserIp())){
//                    t.setOrigUrl(i.getCdnUrl());
//                }
            }
        });
    }

    @Override
    public InfoListVo<RecommendVo> getImgItem(BaseQuery baseQuery, String url, PageBaseParam param) {
        final ImgItemsPo itemsPo = imgChannelDao.getByUrl(url);
//        PageHelper.startPage(param.getStart(), param.getLimit());
        List<ImgItemsItemPo> list = imgChannelDao.getItem(url);
        return VoBuilder.buildPageInfoVo(list, RecommendVo.class,new VoBuilder.BuildAction<ImgItemsItemPo,RecommendVo>(){
            @Override
            public void action(ImgItemsItemPo i, RecommendVo t) {
                t.setActionUrl(i.getPicUrl().trim());
                t.setAdsPopShow(false);
                t.setAdsShow(false);
                t.setImg(i.getPicUrl().trim());
                float r =(float)RandomUtils.nextInt(5);
                float l = 1+(r/10l);
                t.setRate(l);
                t.setTitle("");
                t.setBaseurl(itemsPo.getBaseurl());
//                t.setDataType(Constant.dataType_IMG_CHANNEL);

            }
        },param.getLimit());
    }


}

