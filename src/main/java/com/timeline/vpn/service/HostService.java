package com.timeline.vpn.service;

import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.LocationVo;
import com.timeline.vpn.model.vo.ServerVo;

/**
 * @author gqli
 * @date 2016年3月7日 下午1:23:57
 * @version V1.0
 */
public interface HostService {
    public ServerVo getHostInfo(BaseQuery baseQuery,int location);
    public InfoListVo<LocationVo> getAllLocation();
}

