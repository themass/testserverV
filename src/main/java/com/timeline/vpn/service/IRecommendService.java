package com.timeline.vpn.service;

import java.util.List;

import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.po.RecommendPo;

/**
 * @author gqli
 * @date 2017年11月28日 下午6:27:41
 * @version V1.0
 */
public interface IRecommendService {
    public List<RecommendPo> getPage(int type);
    public List<RecommendPo> getAreaPage(BaseQuery baseQuery);
    public List<RecommendPo> getVipPage(BaseQuery baseQuery);
    public List<RecommendPo> getCustomePage(String name);
    public List<RecommendPo> getCustomeAllPage();
    public void delCustome(Integer id);
    public void replaceCustome(RecommendPo po);
    public List<RecommendPo> getRecoPage();

    public List<RecommendPo> getLocal();
}

