package com.timeline.vpn.service;

import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.PageBaseParam;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.RecommendVo;
import com.timeline.vpn.model.vo.TextItemVo;
import com.timeline.vpn.model.vo.TextItemsVo;

/**
 * @author gqli
 * @date 2016年3月10日 下午4:44:14
 * @version V1.0
 */
public interface DataTextService {
    
    public InfoListVo<RecommendVo> getAllTextChannel(BaseQuery baseQuery, PageBaseParam param);
    public InfoListVo<TextItemsVo> getTextItems(BaseQuery baseQuery, PageBaseParam param,String channel,String keyword);
    public TextItemVo getTextItem(BaseQuery baseQuery, Integer id);
}

