package com.timeline.vpn.service;

import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.PageBaseParam;
import com.timeline.vpn.model.vo.ImgItemVo;
import com.timeline.vpn.model.vo.ImgItemsVo;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.RecommendVo;

/**
 * @author gqli
 * @date 2016年3月10日 下午4:44:14
 * @version V1.0
 */
public interface DataImgService {
    
    public InfoListVo<RecommendVo> getAllImgChannel(BaseQuery baseQuery, PageBaseParam param,String channel);
    public InfoListVo<ImgItemsVo> getImgItems(BaseQuery baseQuery, PageBaseParam param,String channel,String keywork);
    public InfoListVo<ImgItemVo> getImgItem(BaseQuery baseQuery, String url);
    public InfoListVo<RecommendVo> getImgItem(BaseQuery baseQuery, String url,PageBaseParam param);
    public InfoListVo<RecommendVo> getImgItemImgs(BaseQuery baseQuery, PageBaseParam param,
            String channel,String keywork);
    
}

