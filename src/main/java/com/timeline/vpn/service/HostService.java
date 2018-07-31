package com.timeline.vpn.service;

import java.util.List;

import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.DnsResverVo;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.LocationVo;
import com.timeline.vpn.model.vo.ServerVo;
import com.timeline.vpn.model.vo.VipLocationVo;

/**
 * @author gqli
 * @date 2016年3月7日 下午1:23:57
 * @version V1.0
 */
public interface HostService {
    public ServerVo getHostInfo(BaseQuery baseQuery, int location);
    public InfoListVo<LocationVo> getAllLocation();
    public InfoListVo<DnsResverVo> getDnsResver(BaseQuery baseQuery,List<String> domains);
    public InfoListVo<LocationVo> getAllLocationCache(Integer type);
    public ServerVo getHostInfoById(BaseQuery baseQuery, int id);
    public InfoListVo<VipLocationVo> getAllLocationVipCache();
}

