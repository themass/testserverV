package com.timeline.vpn.service;

import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.DevApp;
import com.timeline.vpn.model.param.PageBaseParam;
import com.timeline.vpn.model.vo.*;

/**
 * @author gqli
 * @date 2016年3月10日 下午4:44:14
 * @version V1.0
 */
public interface DataService {
    public InfoListVo<RecommendVo> getRecommendPage(BaseQuery baseQuery,PageBaseParam param);
    
    public InfoListVo<RecommendVo> getRecommendMoviePage(BaseQuery baseQuery);
    public InfoListVo<RecommendVo> getRecommendMoviePage2(BaseQuery baseQuery);
    public InfoListVo<RecommendVo> getRecommendNightPage(BaseQuery baseQuery, PageBaseParam param);
    public InfoListVo<RecommendVo> getRecommendAreaPage(BaseQuery baseQuery, PageBaseParam param);
    
    public InfoListVo<RecommendVo> getRecommendVipPage(BaseQuery baseQuery,PageBaseParam param);
    public InfoListVo<RecommendVo> getRecommendRecPage(BaseQuery baseQuery,PageBaseParam param);

    public InfoListVo<IWannaVo> getIwannaPage(BaseQuery baseQuery, PageBaseParam param);
    public InfoListVo<IWannnWeixinVo> getIwannaWeiXin();
    public IWannaVo addIwanna(BaseQuery baseQuery, String content);
    public void addIwannaLike(BaseQuery baseQuery, long id);
    
    public InfoListVo<IWannaVo> getIwannaScorePage(BaseQuery baseQuery, PageBaseParam param);
    public IWannaVo addIwannaScore(BaseQuery baseQuery, String content);
    public void addIwannaScoreLike(BaseQuery baseQuery, long id);
    
    public VersionInfoVo getVersion(BaseQuery baseQuery,String platform,String channel);
    public VersionInfoVo getMaxVersion(DevApp app,String channel);
    
    
    public InfoListVo<AppInfoVo> getAllApp(BaseQuery baseQuery);
    public InfoListVo<AppInfoVo> getAllDon(BaseQuery baseQuery);
    public DomainVo  getAllDomain(BaseQuery baseQuery);
    public String getAsstoken();
    public void sendMsg(String msg);
   
    
}

