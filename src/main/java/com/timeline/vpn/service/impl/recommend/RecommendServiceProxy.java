package com.timeline.vpn.service.impl.recommend;

import java.util.List;

import org.springframework.stereotype.Component;

import com.timeline.vpn.model.po.RecommendPo;
import com.timeline.vpn.service.IRecommendService;
import com.timeline.vpn.service.strategy.BaseMapServiceProxy;

/**
 * @author gqli
 * @date 2017年11月28日 下午6:29:08
 * @version V1.0
 */
@Component
public class RecommendServiceProxy extends BaseMapServiceProxy<BaseRecommendServie>implements IRecommendService{
    @Override
    public List<RecommendPo> getPage(int type) {
        return getService().getPage(type);
    }

    @Override
    public List<RecommendPo> getVipPage() {
        return getService().getVipPage();
    }

    @Override
    public List<RecommendPo> getCustomePage(String name) {
        return getService().getCustomePage(name);
    }

    @Override
    public List<RecommendPo> getCustomeAllPage() {
        return getService().getCustomeAllPage();
    }

    @Override
    public void delCustome(Integer id) {
        getService().delCustome(id);        
    }

    @Override
    public void replaceCustome(RecommendPo po) {
        getService().replaceCustome(po);        
    }

    @Override
    public List<RecommendPo> getRecoPage() {
        return getService().getRecoPage();
    }

    @Override
    protected String getDefaultName() {
        return null;
    }

    @Override
    public List<RecommendPo> getAreaPage() {
        return getService().getAreaPage();
    }

}

