package com.timeline.vpn.service.impl;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import com.github.pagehelper.Page;
import com.github.pagehelper.PageHelper;
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
                t.setImg(i.getPic());
                t.setAdsPopShow(true);
                t.setAdsShow(true);
                if(i.getShowType()==null)
                    t.setShowType(0);
                t.setParam(i.getUrl());
            }
        });
    }

    @Override
    public InfoListVo<ImgItemsVo> getImgItems(BaseQuery baseQuery, PageBaseParam param,
            String channel) {
        PageHelper.startPage(param.getStart(), param.getLimit());
        List<ImgItemsPo> poList = imgChannelDao.getByChannel(channel);
        return VoBuilder.buildPageInfoVo((Page<ImgItemsPo>) poList, ImgItemsVo.class,null);
    }
    @Override
    public InfoListVo<RecommendVo> getImgItemImgs(BaseQuery baseQuery, PageBaseParam param,
            String channel) {
        PageHelper.startPage(param.getStart(), param.getLimit());
        List<ImgItemsPo> poList = imgChannelDao.getByChannel(channel);
        return VoBuilder.buildPageInfoVo((Page<ImgItemsPo>)poList, RecommendVo.class,new VoBuilder.BuildAction<ImgItemsPo,RecommendVo>(){
            @Override
            public void action(ImgItemsPo i, RecommendVo t) {
                t.setActionUrl(i.getUrl());
                t.setTitle(i.getName());
                t.setImg(i.getPic());
//                if(!StringUtils.isEmpty(i.getPic()))
//                    if(i.getPic().contains("eroti-cart")){
//                        t.setImg("http://173.212.239.199/file/eroti/"+i.getId()+".jpg");
//                    }else if(i.getPic().contains("singlove.com")){
//                        t.setImg("http://173.212.239.199/file/hhh/"+i.getId()+".jpg");
//                    }
                t.setAdsPopShow(false);
                t.setAdsShow(true);
//                t.setShowType(0);
//                t.setRate(1.2f);
                t.setShowLogo(i.getPics()+"张");
            }
        });
    }
    @Override
    public InfoListVo<ImgItemVo> getImgItem(final BaseQuery baseQuery, String url) {
        List<ImgItemsItemPo> list = imgChannelDao.getItem(url);
        return VoBuilder.buildListInfoVo(list, ImgItemVo.class,new VoBuilder.BuildAction<ImgItemsItemPo,ImgItemVo>(){
            @Override
            public void action(ImgItemsItemPo i, ImgItemVo t) {
                t.setOrigUrl(i.getPicUrl());
                t.setRemoteUrl(i.getPicUrl());
                if(!StringUtils.isEmpty(i.getPicUrl()))
                    if(i.getPicUrl().contains("eroti-cart")){
                        t.setPicUrl("http://imghhh.secondary.space/file/eroti/"+i.getId()+".jpg");
                        t.setOrigUrl("http://imghhh.secondary.space/file/eroti/"+i.getId()+".jpg");
                    }else if(i.getPicUrl().contains("singlove.com")){
                        t.setPicUrl("http://imghhh.secondary.space/file/hhh/"+i.getId()+".jpg");
                        t.setOrigUrl("http://imghhh.secondary.space/file/hhh/"+i.getId()+".jpg");
                    }
                if(!StringUtils.isEmpty(i.getPicUrl()))
                    if(i.getPicUrl().contains("eroti-cart")){
                        t.setRemoteUrl("http://imghhh.secondary.space/file/eroti/"+i.getId()+".jpg");
                    }else if(i.getPicUrl().contains("singlove.com")){
                        t.setRemoteUrl("http://imghhh.secondary.space/file/hhh/"+i.getId()+".jpg");
                    }
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


}

