package com.timeline.vpn.service;

import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.CharacterVo;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.model.vo.InfoListVo;

/**
 * @author gqli
 * @date 2016年3月10日 下午4:44:14
 * @version V1.0
 */
public interface ChatService {
    
    public Choice chatWithGpt(BaseQuery baseQuery, String content,String id, String charater) throws Exception;
    public InfoListVo<CharacterVo> getCharacter(BaseQuery baseQuery);


}

