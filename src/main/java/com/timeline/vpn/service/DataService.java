package com.timeline.vpn.service;

import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.PageBaseParam;
import com.timeline.vpn.model.vo.IWannaVo;
import com.timeline.vpn.model.vo.ImgItemVo;
import com.timeline.vpn.model.vo.ImgItemsVo;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.RecommendVo;
import com.timeline.vpn.model.vo.SoundItemsVo;
import com.timeline.vpn.model.vo.TextItemVo;
import com.timeline.vpn.model.vo.TextItemsVo;
import com.timeline.vpn.model.vo.VersionInfoVo;

/**
 * @author gqli
 * @date 2016年3月10日 下午4:44:14
 * @version V1.0
 */
public interface DataService {
    public InfoListVo<RecommendVo> getRecommendPage(BaseQuery baseQuery,PageBaseParam param);
    public InfoListVo<RecommendVo> getRecommendVipPage(BaseQuery baseQuery,PageBaseParam param);
    public InfoListVo<RecommendVo> getRecommendRecPage(BaseQuery baseQuery,PageBaseParam param);

    public InfoListVo<IWannaVo> getIwannaPage(BaseQuery baseQuery, PageBaseParam param);

    public IWannaVo addIwanna(BaseQuery baseQuery, String content);

    public void addIwannaLike(BaseQuery baseQuery, long id);

    public VersionInfoVo getVersion(BaseQuery baseQuery,String platform,String channel);
    
    public InfoListVo<RecommendVo> getAllSoundChannel(BaseQuery baseQuery, PageBaseParam param);
    public InfoListVo<SoundItemsVo> getSoundItems(BaseQuery baseQuery, PageBaseParam param,String channel);
    
    public InfoListVo<RecommendVo> getAllTextChannel(BaseQuery baseQuery, PageBaseParam param);
    public InfoListVo<TextItemsVo> getTextItems(BaseQuery baseQuery, PageBaseParam param,String channel,String keyword);
    public TextItemVo getTextItem(BaseQuery baseQuery, Integer id);
    
    public InfoListVo<RecommendVo> getAllImgChannel(BaseQuery baseQuery, PageBaseParam param);
    public InfoListVo<ImgItemsVo> getImgItems(BaseQuery baseQuery, PageBaseParam param,String channel);
    public InfoListVo<ImgItemVo> getImgItem(BaseQuery baseQuery, String url);
    public InfoListVo<RecommendVo> getVideoPage(BaseQuery baseQuery,PageBaseParam param);
    
}

