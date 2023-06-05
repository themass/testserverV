package com.timeline.vpn.service.impl;

import java.util.List;

import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.github.pagehelper.Page;
import com.github.pagehelper.PageHelper;
import com.timeline.vpn.VoBuilder;
import com.timeline.vpn.dao.db.TextChannelDao;
import com.timeline.vpn.exception.DataException;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.PageBaseParam;
import com.timeline.vpn.model.po.TextChannelPo;
import com.timeline.vpn.model.po.TextItemPo;
import com.timeline.vpn.model.po.TextItemsPo;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.RecommendVo;
import com.timeline.vpn.model.vo.TextItemVo;
import com.timeline.vpn.model.vo.TextItemsVo;
import com.timeline.vpn.service.DataTextService;

/**
 * @author gqli
 * @date 2016年3月10日 下午4:45:36
 * @version V1.0
 */
@Service
public class DataTextServiceImpl implements DataTextService {

    @Autowired
    private TextChannelDao textChannelDao;

    @Override
    public InfoListVo<RecommendVo> getAllTextChannel(BaseQuery baseQuery, PageBaseParam param) {
        List<TextChannelPo> list = textChannelDao.getAll();
        return VoBuilder.buildListInfoVo(list, RecommendVo.class,new VoBuilder.BuildAction<TextChannelPo,RecommendVo>(){
            @Override
            public void action(TextChannelPo i, RecommendVo t) {
                t.setActionUrl(i.getName());
                t.setTitle(i.getName());
                t.setAdsPopShow(true);
                t.setAdsShow(true);
                t.setParam(i.getName());
                t.setShowLogo(i.getCount()+"篇文章");
            }
        });
    }

    @Override
    public InfoListVo<TextItemsVo> getTextItems(final BaseQuery baseQuery, PageBaseParam param,
            String channel,String keyword) {
        PageHelper.startPage(param.getStart(), param.getLimit());
        if(!StringUtils.isEmpty(keyword)) {
            channel = null;
        }
        List<TextItemsPo> poList = textChannelDao.getByChannel(channel,keyword);
        return VoBuilder.buildPageInfoVo((Page<TextItemsPo>) poList, TextItemsVo.class,new VoBuilder.BuildAction<TextItemsPo,TextItemsVo>(){

            @Override
            public void action(TextItemsPo i, TextItemsVo t) {
                t.setFileUrl(CdnChooseUtil.getBookWebBaseUrl(baseQuery.getAppInfo().getUserIp())+"&id="+i.getId());
            }
        }
        );
    }

    @Override
    public TextItemVo getTextItem(BaseQuery baseQuery, Integer id) {
        TextItemPo po = textChannelDao.getFile(id);
        if(po==null){
            throw new DataException();
        }
        return VoBuilder.buildVo(po, TextItemVo.class, null);
    }

}

