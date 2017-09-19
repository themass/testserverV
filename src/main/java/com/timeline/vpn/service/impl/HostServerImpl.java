package com.timeline.vpn.service.impl;

import java.util.ArrayList;
import java.util.List;

import org.apache.commons.lang3.RandomUtils;
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
import com.timeline.vpn.model.po.LocationPo;
import com.timeline.vpn.model.po.RadCheck;
import com.timeline.vpn.model.po.UserPo;
import com.timeline.vpn.model.vo.DnsResverVo;
import com.timeline.vpn.model.vo.HostVo;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.LocationVo;
import com.timeline.vpn.model.vo.ServerVo;
import com.timeline.vpn.model.vo.VoBuilder;
import com.timeline.vpn.model.vo.VoBuilder.BuildAction;
import com.timeline.vpn.service.HostService;
import com.timeline.vpn.service.RadUserCheckService;
import com.timeline.vpn.service.job.reload.HostIpCache;
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
        
        BuildAction<HostPo, HostVo> action = null;
        List<HostPo> hostList = new ArrayList<>();
        if (location == Constant.LOCATION_ALL) {
            List<HostPo> list = hostDao.getRandom();
            //优化成连接数最少或者网络带宽最好的一个
            hostList.add(list.get(RandomUtils.nextInt(0, list.size())));
            hostList.add(list.get(RandomUtils.nextInt(0, list.size())));
        } else {
            LocationPo loc = cityDao.get(location);
            if(loc==null){
                throw new DataException(Constant.ResultMsg.RESULT_DATA_ERROR);
            }
            if(!checkPermission(loc.getType(),baseQuery.getUser())){
                throw new DataException(Constant.ResultMsg.RESULT_PERM_ERROR);
            }
            hostList = hostDao.getByLocation(location);
        }
        if (CollectionUtils.isEmpty(hostList)) {
            throw new DataException(Constant.ResultMsg.RESULT_DATA_ERROR);
        }
        return VoBuilder.buildServerVo(check.getUserName(),check.getValue(),Constant.ServeType.SERVER_TYPE_FREE, hostList,action);
    }
    @Override
    public ServerVo getHostInfoById(BaseQuery baseQuery, int id){
        RadCheck check = null;
        String name = baseQuery.getUser()==null?baseQuery.getAppInfo().getDevId():baseQuery.getUser().getName();
        check = checkService.getRadUser(name);
        if(check==null){
            check = checkService.addRadUser(baseQuery.getAppInfo().getDevId(), AES2.getRandom(), Constant.UserGroup.RAD_GROUP_FREE);
        }
        
        BuildAction<HostPo, HostVo> action = null;
        List<HostPo> hostList = new ArrayList<>();
        if (id == Constant.LOCATION_ALL) {
            List<HostPo> list = hostDao.getRandom();
            //优化成连接数最少或者网络带宽最好的一个
            hostList.add(list.get(RandomUtils.nextInt(0, list.size())));
            hostList.add(list.get(RandomUtils.nextInt(0, list.size())));
        } else {
            HostPo host = hostDao.get(id);
            if(host==null){
                throw new DataException(Constant.ResultMsg.RESULT_DATA_ERROR);
            }
            if(!checkPermission(host.getType(),baseQuery.getUser())){
                throw new DataException(Constant.ResultMsg.RESULT_PERM_ERROR);
            }
            hostList.add(host);
        }
        if (CollectionUtils.isEmpty(hostList)) {
            throw new DataException(Constant.ResultMsg.RESULT_DATA_ERROR);
        }
        return VoBuilder.buildServerVo(check.getUserName(),check.getValue(),Constant.ServeType.SERVER_TYPE_FREE, hostList,action);
    }
    private boolean checkPermission(int type,UserPo user){
        //免费服务器
        if(type==Constant.ServeType.SERVER_TYPE_FREE){
            return true;
        }else{//VIP服务器
            if(user==null){
                return false;
            }else if(user.getLevel()==Constant.UserLevel.LEVEL_VIP2){
                return true;
            }else if(user.getLevel()==Constant.UserLevel.LEVEL_VIP && type ==Constant.ServeType.SERVER_TYPE_VIP2){
                return false;
            }
        }
        return true;
    }
    @Override
    public InfoListVo<LocationVo> getAllLocation() {
        return VoBuilder.buildListInfoVo(cityDao.getAll(), LocationVo.class,null);
    }
    @Override
    public InfoListVo<LocationVo> getAllLocationCache() {
        return VoBuilder.buildListInfoVo(HostIpCache.getLocationList(), LocationVo.class,null);
    }

    @Override
    public InfoListVo<DnsResverVo> getDnsResver(BaseQuery baseQuery,List<String> domains) {
        List<DnsResverPo> list = dnsResverDao.get(domains);
        return VoBuilder.buildDnsResverInfoList(list);
    }

}

