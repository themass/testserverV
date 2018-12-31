package com.timeline.vpn.service.impl;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;

import org.apache.commons.lang3.RandomUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.util.CollectionUtils;

import com.google.common.base.Function;
import com.timeline.vpn.BeanBuilder;
import com.timeline.vpn.Constant;
import com.timeline.vpn.VoBuilder;
import com.timeline.vpn.VoBuilder.BuildAction;
import com.timeline.vpn.dao.db.DnsResverDao;
import com.timeline.vpn.dao.db.HostDao;
import com.timeline.vpn.dao.db.HostV2Dao;
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
import com.timeline.vpn.model.vo.VipLocationVo;
import com.timeline.vpn.service.HostService;
import com.timeline.vpn.service.RadUserCheckService;
import com.timeline.vpn.service.job.reload.HostCheck;
import com.timeline.vpn.service.job.reload.HostIpCache;
import com.timeline.vpn.service.job.reload.HostIpCacheV2;
import com.timeline.vpn.service.job.reload.HostIpCacheV2Vpnb;
import com.timeline.vpn.service.job.reload.HostIpCacheVpnb;
import com.timeline.vpn.util.AES2;
import com.timeline.vpn.util.WeightRandom;

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
    private HostV2Dao hostV2Dao;
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
        String channel = Constant.VPN;
        if(Constant.VPNB.equals(baseQuery.getAppInfo().getNetType())||Constant.VPNC.equals(baseQuery.getAppInfo().getNetType())||Constant.VPND.equals(baseQuery.getAppInfo().getNetType())) {
          channel = Constant.VPNB;
        }
        if (location == Constant.LOCATION_ALL) {
            List<HostPo> list = hostDao.getRandom(channel);
            //优化成连接数最少或者网络带宽最好的一个
            hostList.add(list.get(RandomUtils.nextInt(0, list.size())));
            hostList.add(list.get(RandomUtils.nextInt(0, list.size())));
        } else {
            LocationPo loc = cityDao.get(location);
            if(loc==null){
                throw new DataException(Constant.ResultMsg.RESULT_HOST_ERROR);
            }
            if(!checkPermission(loc.getType(),baseQuery.getUser())){
                throw new DataException(Constant.ResultMsg.RESULT_PERM_ERROR);
            }
            hostList = hostDao.getByLocation(location);
        }
        if (CollectionUtils.isEmpty(hostList)) {
            throw new DataException(Constant.ResultMsg.RESULT_HOST_ERROR);
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
        HostPo host = hostV2Dao.get(id);
        if(host==null){
            throw new DataException(Constant.ResultMsg.RESULT_HOST_ERROR);
        }
        hostList.add(host);
        if (CollectionUtils.isEmpty(hostList)) {
            throw new DataException(Constant.ResultMsg.RESULT_HOST_ERROR);
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
            }else if(user.getLevel()>=type){
                return true;
            }
        }
        return false;
    }
    @Override
    public InfoListVo<LocationVo> getAllLocation() {
        return VoBuilder.buildListInfoVo(cityDao.getAll(), LocationVo.class,null);
    }
    @Override
    public InfoListVo<LocationVo> getAllLocationCache(BaseQuery baseQuery,Integer type) {
        List<LocationPo> list = new ArrayList<>();
        if(Constant.VPNB.equals(baseQuery.getAppInfo().getNetType())||Constant.VPNC.equals(baseQuery.getAppInfo().getNetType())||Constant.VPND.equals(baseQuery.getAppInfo().getNetType())) {
            list = HostIpCacheVpnb.getLocationList();
          }else {
            list = HostIpCache.getLocationList();
          }
        List<LocationPo> ret = new ArrayList<>();
        for(LocationPo po : list) {
            if(po.getType()==type) {
                ret.add(po);
            }
        }
        return VoBuilder.buildListInfoVo(ret, LocationVo.class,null);
    }
    @Override
    public InfoListVo<VipLocationVo> getAllLocationVipCache(BaseQuery baseQuery) {
      List<LocationPo> list = null;
      if(Constant.VPNB.equals(baseQuery.getAppInfo().getNetType())||Constant.VPNC.equals(baseQuery.getAppInfo().getNetType())||Constant.VPND.equals(baseQuery.getAppInfo().getNetType())) {
        list = HostIpCacheVpnb.getLocationList();
      }else {
        list = HostIpCache.getLocationList();
      }
      InfoListVo<LocationVo> locationVo = VoBuilder.buildListInfoVo(list, LocationVo.class,null);
      Map<Integer, Collection<LocationVo>> map =BeanBuilder.buildMultimap(locationVo.getVoList(), new Function<LocationVo, Integer>() {

          @Override
          public Integer apply(LocationVo input) {
              return input.getType();
          }
      });
      return VoBuilder.buildListVipLocationVo(map);
    }
    @Override
    public InfoListVo<DnsResverVo> getDnsResver(BaseQuery baseQuery,List<String> domains) {
        List<DnsResverPo> list = dnsResverDao.get(domains);
        return VoBuilder.buildDnsResverInfoList(list);
    }
    @Override
    public InfoListVo<LocationVo> getAllLocationCacheV2(BaseQuery baseQuery,Integer type) {
        List<LocationPo> list = new ArrayList<>();
        if(Constant.VPNB.equals(baseQuery.getAppInfo().getNetType())||Constant.VPNC.equals(baseQuery.getAppInfo().getNetType())||Constant.VPND.equals(baseQuery.getAppInfo().getNetType())) {
            list = HostIpCacheV2Vpnb.getLocationList();
          }else {
            list = HostIpCacheV2.getLocationList();
          }
        List<LocationPo> ret = new ArrayList<>();
        for(LocationPo po : list) {
            if(po.getType()==type) {
                ret.add(po);
            }
        }
        return VoBuilder.buildListInfoVo(ret, LocationVo.class,null);
    }
    @Override
    public ServerVo getHostInfoV2(BaseQuery baseQuery, int location) {
        RadCheck check = null;
        String name = baseQuery.getUser()==null?baseQuery.getAppInfo().getDevId():baseQuery.getUser().getName();
        check = checkService.getRadUser(name);
        if(check==null){
            check = checkService.addRadUser(baseQuery.getAppInfo().getDevId(), AES2.getRandom(), Constant.UserGroup.RAD_GROUP_FREE);
        }
        
        BuildAction<HostPo, HostVo> action = null;
        
        List<HostPo> hostList = hostV2Dao.getByLocation(location);
        if (CollectionUtils.isEmpty(hostList)) {
            throw new DataException(Constant.ResultMsg.RESULT_HOST_ERROR);
        }
        List<HostPo> hostRet = new ArrayList<>();
        for(HostPo po :hostList) {
            if(!HostCheck.isErrorIp(po.getGateway())) {
                hostRet.add(po);
            }
        }
        if(CollectionUtils.isEmpty(hostRet)) {
            throw new DataException(Constant.ResultMsg.RESULT_HOST_ERROR);
        }
        WeightRandom random = new WeightRandom(hostRet);
        List<HostPo> ret = new ArrayList<>();
        ret.add(random.random());
        return VoBuilder.buildServerVo(check.getUserName(),check.getValue(),Constant.ServeType.SERVER_TYPE_FREE, ret,action);
    }
    @Override
    public InfoListVo<VipLocationVo> getAllLocationVipCacheV2(BaseQuery baseQuery) {
        List<LocationPo> list = null;
        if(Constant.VPNB.equals(baseQuery.getAppInfo().getNetType())||Constant.VPNC.equals(baseQuery.getAppInfo().getNetType())||Constant.VPND.equals(baseQuery.getAppInfo().getNetType())) {
          list = HostIpCacheV2Vpnb.getLocationList();
        }else {
          list = HostIpCacheV2.getLocationList();
        }
        InfoListVo<LocationVo> locationVo = VoBuilder.buildListInfoVo(list, LocationVo.class,null);
        Map<Integer, Collection<LocationVo>> map =BeanBuilder.buildMultimap(locationVo.getVoList(), new Function<LocationVo, Integer>() {

            @Override
            public Integer apply(LocationVo input) {
                return input.getType();
            }
        });
        return VoBuilder.buildListVipLocationVo(map);
    }

}

