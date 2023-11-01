package com.timeline.vpn.service;

import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.PageBaseParam;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.RecommendVo;

/**
 * @author gqli
 * @date 2016年3月10日 下午4:44:14
 * @version V1.0
 */
public interface DataVideoService {

    InfoListVo<RecommendVo> getVideoPage(BaseQuery baseQuery, PageBaseParam param);

    InfoListVo<RecommendVo> getVideoChannel(BaseQuery baseQuery, String channelType);

    InfoListVo<RecommendVo> getVideoChannelItemsPage(BaseQuery baseQuery, PageBaseParam param,
            String channel,String keywork,String channelOrg);

    InfoListVo<RecommendVo> getVideoUserPage(BaseQuery baseQuery, PageBaseParam param,String channel);

    InfoListVo<RecommendVo> getVideoUserItemsPage(BaseQuery baseQuery, PageBaseParam param,
            String userId,String keyword);
    
    InfoListVo<RecommendVo> getVideoTvItemPage(BaseQuery baseQuery, PageBaseParam param,String channel);

    InfoListVo<RecommendVo> getVideoTvChannelPage(BaseQuery baseQuery, PageBaseParam param, String channel,String keyword);

    RecommendVo getVideoUrl(BaseQuery baseQuery, PageBaseParam param, long id);

}

