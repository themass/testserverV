package com.timeline.vpn.service.impl.handle.recommend;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import com.timeline.vpn.Constant;
import com.timeline.vpn.dao.db.SexTempRecommendDao;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.po.RecommendPo;

/**
 * @author gqli
 * @date 2017年11月28日 下午6:38:29
 * @version V1.0
 */
@Component
public class SexTempRecommendServiceImpl implements BaseRecommendServie{
    @Autowired
    private SexTempRecommendDao recommendDao;
    @Override
    public List<RecommendPo> getPage(int type) {
        return recommendDao.getPage(type);
    }

    @Override
    public List<RecommendPo> getVipPage(BaseQuery baseQuery) {  
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
    public List<RecommendPo> getLocal() {
        return recommendDao.getLocal();
    }

    @Override
    public String getAgent() {
        return Constant.SEX_TEMP;
    }

    @Override
    public List<RecommendPo> getAreaPage(BaseQuery baseQuery) {
        return null;
    }

}

