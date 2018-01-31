package com.timeline.vpn.service.impl.recommend;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import com.timeline.vpn.Constant;
import com.timeline.vpn.dao.db.SexRecommendDao;
import com.timeline.vpn.model.po.RecommendPo;

/**
 * @author gqli
 * @date 2017年11月28日 下午6:38:29
 * @version V1.0
 */
@Component
public class SexRecommendServiceImpl implements BaseRecommendServie{
    @Autowired
    private SexRecommendDao recommendDao;
    @Override
    public List<RecommendPo> getPage(int type) {
        return recommendDao.getPage(type);
    }

    @Override
    public List<RecommendPo> getVipPage() {
        return recommendDao.getVipPage();
    }

    @Override
    public List<RecommendPo> getCustomePage(String name) {
        return recommendDao.getCustomePage(name);
    }

    @Override
    public List<RecommendPo> getCustomeAllPage() {
        return recommendDao.getCustomeAllPage();
    }

    @Override
    public void delCustome(Integer id) {
        recommendDao.delCustome(id);
    }

    @Override
    public void replaceCustome(RecommendPo po) {
        recommendDao.replaceCustome(po);        
    }

    @Override
    public List<RecommendPo> getRecoPage() {
        return recommendDao.getRecoPage();
    }

    @Override
    public String getAgent() {
        return Constant.SEX;
    }

    @Override
    public List<RecommendPo> getAreaPage() {
        return recommendDao.getAreaPage();
    }

}

