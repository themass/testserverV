package com.timeline.vpn.service;

import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.*;

import java.util.List;

/**
 * @author gqli
 * @date 2016年3月7日 下午1:23:57
 * @version V1.0
 */
public interface HostService {

    public InfoListVo<DnsResverVo> getDnsResver(BaseQuery baseQuery,List<String> domains);
    public ServerVo getHostInfoById(BaseQuery baseQuery, int id);
    public ServerVo getHostInfoV2(BaseQuery baseQuery, int id);

    public InfoListVo<LocationVo> getAllLocationCacheV2(BaseQuery baseQuery,Integer type);
    public InfoListVo<VipLocationVo> getAllLocationVipCacheV2(BaseQuery baseQuery);
}

