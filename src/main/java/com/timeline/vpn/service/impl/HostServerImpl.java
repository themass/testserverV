package com.timeline.vpn.service.impl;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;

import org.apache.commons.lang3.RandomUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.util.CollectionUtils;
import org.springframework.util.StringUtils;

import com.google.common.base.Function;
import com.timeline.vpn.BeanBuilder;
import com.timeline.vpn.Constant;
import com.timeline.vpn.VoBuilder;
import com.timeline.vpn.VoBuilder.BuildAction;
import com.timeline.vpn.dao.db.DnsResverDao;
import com.timeline.vpn.dao.db.HostDao;
import com.timeline.vpn.dao.db.HostV2Dao;
import com.timeline.vpn.dao.db.LocationDao;
import com.timeline.vpn.dao.db.LocationV2Dao;
import com.timeline.vpn.exception.DataException;
import com.timeline.vpn.exception.LoginException;
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
import com.timeline.vpn.service.job.reload.HostIpCacheV2Vpnd;
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
    private static final Logger LOGGER =
            LoggerFactory.getLogger(HostServerImpl.class);
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
    @Autowired
    private LocationV2Dao cityV2Dao;

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
//      if(Constant.VPNC.equals(baseQuery.getAppInfo().getNetType())&&Constant.LANG_ZH.equals(baseQuery.getAppInfo().getLang())) {
//          map.remove(0);
//          map.remove(1);
//          LOGGER.info("中国灯塔用户 3  1000008024->"+map.keySet());
//      }
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
        if(Constant.VPNB.equals(baseQuery.getAppInfo().getNetType())||Constant.VPNC.equals(baseQuery.getAppInfo().getNetType())) {
            list = HostIpCacheV2Vpnb.getLocationList();
          }else if(Constant.VPND.equals(baseQuery.getAppInfo().getNetType())){
              list = HostIpCacheV2Vpnd.getLocationList();
          }else {
            list = HostIpCacheV2.getLocationList();
          }
        List<LocationPo> ret = new ArrayList<>();
        for(LocationPo po : list) {
            if(po.getType()==type) {
                ret.add(po);
            }
        }
        if(baseQuery.getUser()!=null && Constant.userNodog.contains(baseQuery.getUser().getName()) &&RandomUtils.nextInt(1, 6)==5) {
            throw new LoginException(Constant.ResultMsg.RESULT_LOGIN_ERROR);
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
        boolean log = false;
//        if(Constant.VPNC.equals(baseQuery.getAppInfo().getNetType())&&Constant.LANG_ZH.equals(baseQuery.getAppInfo().getLang())&&location<2) {
//            LOGGER.info("中国灯塔用户 2  1000008024"); 
//            throw new DataException("灯塔提示：请使用AFree,账号通用.\n试试分享,有下载链接！！");
//        }
        if(location==0) {
            log = true;
           if(Constant.LANG_ZH.equals(baseQuery.getAppInfo().getLang())) {
                List<HostPo> sha = hostV2Dao.getByLocation(-1);
                LOGGER.info("ipport:中国线路，增加鲨鱼 : "+sha.size());
                hostList.addAll(sha);
            }else {
                List<HostPo> sha = hostV2Dao.getByLocation(-2);
                LOGGER.info("ipport:国外线路，增加欧洲 : "+sha.size());
                hostList.addAll(sha);
            }
        }
        if (CollectionUtils.isEmpty(hostList)) {
            throw new LoginException(Constant.ResultMsg.RESULT_HOST_ERROR);
        }else {
            if(!StringUtils.isEmpty(hostList.get(0).getShowName()) && hostList.get(0).getShowName().contains("菲律宾") && baseQuery.getUser()==null) {
                throw new LoginException(Constant.ResultErrno.ERRNO_NEED_LOGIN,Constant.ResultMsg.RESULT_ERROR_NEEDUSER);
            }
        }
        LocationPo loc = cityV2Dao.get(location);
        if(!StringUtils.isEmpty(hostList.get(0).getShowName()) && hostList.get(0).getShowName().contains("菲律宾")) {
            if(Constant.VPNC.equals(baseQuery.getAppInfo().getNetType())&&Integer.valueOf(baseQuery.getAppInfo().getVersion())<1000008013) {
//                LOGGER.error("ipport:版本低："+baseQuery.getAppInfo());
                throw new LoginException(Constant.ResultMsg.RESULT_VERSION_ERROR);
            }else if(StringUtils.isEmpty(baseQuery.getAppInfo().getNetType())&&Integer.valueOf(baseQuery.getAppInfo().getVersion())<1001008012){
//                LOGGER.error("ipport:版本低："+baseQuery.getAppInfo());
                throw new LoginException(Constant.ResultMsg.RESULT_VERSION_ERROR);
            }
        }
        if(hostList.get(0).getType()==0 && Constant.VPNC.equals(baseQuery.getAppInfo().getNetType())&&Constant.LANG_ZH.equals(baseQuery.getAppInfo().getLang())&&Integer.valueOf(baseQuery.getAppInfo().getVersion())<1000008024) {
            throw new LoginException(Constant.ResultMsg.RESULT_VERSION_ERROR);
        }
        if(loc==null){
            throw new DataException(Constant.ResultMsg.RESULT_HOST_ERROR);
        }
        if(!checkPermission(loc.getType(),baseQuery.getUser())){
            throw new LoginException(Constant.ResultMsg.RESULT_PERM_ERROR);
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
        ret.add(random.random(log));
        
        return VoBuilder.buildServerVo(check.getUserName(),check.getValue(),Constant.ServeType.SERVER_TYPE_FREE, ret,action);
    }
    @Override
    public InfoListVo<VipLocationVo> getAllLocationVipCacheV2(BaseQuery baseQuery) {
        List<LocationPo> list = null;
        if(Constant.VPNB.equals(baseQuery.getAppInfo().getNetType())||Constant.VPNC.equals(baseQuery.getAppInfo().getNetType())) {
          list = HostIpCacheV2Vpnb.getLocationList();
        }else if (Constant.VPND.equals(baseQuery.getAppInfo().getNetType())){
            list = HostIpCacheV2Vpnd.getLocationList();
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

