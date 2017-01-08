package com.timeline.vpn.service.impl;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.util.CollectionUtils;

import com.timeline.vpn.Constant;
import com.timeline.vpn.dao.db.DnsResverDao;
import com.timeline.vpn.dao.db.HostDao;
import com.timeline.vpn.dao.db.LocationDao;
import com.timeline.vpn.exception.DataException;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.po.DnsResverPo;
import com.timeline.vpn.model.po.HostPo;
import com.timeline.vpn.model.po.RadCheck;
import com.timeline.vpn.model.vo.DnsResverVo;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.LocationVo;
import com.timeline.vpn.model.vo.ServerVo;
import com.timeline.vpn.model.vo.VoBuilder;
import com.timeline.vpn.service.HostService;
import com.timeline.vpn.service.RadUserCheckService;
import com.timeline.vpn.util.AES2;

/**
 * @author gqli
 * @date 2016年3月7日 下午1:44:16
 * @version V1.0
 */
@Service
public class HostServerImpl implements HostService {
    @Autowired
    private HostDao hostDao;
    @Autowired
    private LocationDao cityDao;
    @Autowired
    private RadUserCheckService checkService;
    @Autowired
    private DnsResverDao dnsResverDao;

    @Override
    public ServerVo getHostInfo(BaseQuery baseQuery, int location) {
        RadCheck check = null;
        String name = baseQuery.getUser()==null?baseQuery.getAppInfo().getDevId():baseQuery.getUser().getName();
        check = checkService.getRadUser(name);
        if(check==null){
            check = checkService.addRadUser(baseQuery.getAppInfo().getDevId(), AES2.getRandom(), Constant.UserGroup.RAD_GROUP_FREE);
        }
//        UserPass pass = UserAuthData.getOne();
        List<HostPo> hostList = null;
        if (location == Constant.LOCATION_ALL) {
            hostList = hostDao.getAll();
        } else {
            hostList = hostDao.getByLocation(location);
        }
        if (CollectionUtils.isEmpty(hostList)) {
            throw new DataException(Constant.ResultMsg.RESULT_DATA_ERROR);
        }
        return VoBuilder.buildServerVo(check.getUserName(),check.getValue(),Constant.SERVER_TYPE_FREE, hostList);
    }

    @Override
    public InfoListVo<LocationVo> getAllLocation() {
        return VoBuilder.buildListInfoVo(cityDao.getAll(), LocationVo.class);
    }

    @Override
    public InfoListVo<DnsResverVo> getDnsResver(BaseQuery baseQuery,List<String> domains) {
        List<DnsResverPo> list = dnsResverDao.get(domains);
        return VoBuilder.buildDnsResverInfoList(list);
    }

}

