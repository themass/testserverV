package com.timeline.vpn.service;

import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.RecommendVo;
import com.timeline.vpn.model.vo.VersionInfoVo;

/**
 * @author gqli
 * @date 2016年3月10日 下午4:44:14
 * @version V1.0
 */
public interface DataService {
    public InfoListVo<RecommendVo> getRecommendList();
    public VersionInfoVo getVersion(String platform);
}

