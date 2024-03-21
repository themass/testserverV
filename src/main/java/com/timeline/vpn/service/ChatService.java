package com.timeline.vpn.service;

import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.PageBaseParam;
import com.timeline.vpn.model.vo.*;

/**
 * @author gqli
 * @date 2016年3月10日 下午4:44:14
 * @version V1.0
 */
public interface ChatService {
    
    public Choice chatWithGpt(BaseQuery baseQuery, String content,String id) throws Exception;
    
}

