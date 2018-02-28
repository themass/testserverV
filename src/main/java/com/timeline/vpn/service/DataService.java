package com.timeline.vpn.service;

import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.PageBaseParam;
import com.timeline.vpn.model.vo.AppInfoVo;
import com.timeline.vpn.model.vo.IWannaVo;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.RecommendVo;
import com.timeline.vpn.model.vo.VersionInfoVo;

/**
 * @author gqli
 * @date 2016年3月10日 下午4:44:14
 * @version V1.0
 */
public interface DataService {
    public InfoListVo<RecommendVo> getRecommendPage(BaseQuery baseQuery,PageBaseParam param);
    
    public InfoListVo<RecommendVo> getRecommendMoviePage(BaseQuery baseQuery);
    public InfoListVo<RecommendVo> getRecommendNightPage(BaseQuery baseQuery, PageBaseParam param);
    public InfoListVo<RecommendVo> getRecommendAreaPage(BaseQuery baseQuery, PageBaseParam param);
    
    public InfoListVo<RecommendVo> getRecommendVipPage(BaseQuery baseQuery,PageBaseParam param);
    public InfoListVo<RecommendVo> getRecommendRecPage(BaseQuery baseQuery,PageBaseParam param);

    public InfoListVo<IWannaVo> getIwannaPage(BaseQuery baseQuery, PageBaseParam param);

    public IWannaVo addIwanna(BaseQuery baseQuery, String content);

    public void addIwannaLike(BaseQuery baseQuery, long id);

    public VersionInfoVo getVersion(BaseQuery baseQuery,String platform,String channel);
    
    public InfoListVo<AppInfoVo> getAllApp(BaseQuery baseQuery);
    public InfoListVo<AppInfoVo> getAllDon(BaseQuery baseQuery);

    
   
    
}

