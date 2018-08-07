package com.timeline.vpn;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import org.apache.commons.lang.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.BeanUtils;
import org.springframework.util.CollectionUtils;

import com.github.pagehelper.Page;
import com.timeline.vpn.model.enums.LocationTypeNameEnum;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.po.DnsResverPo;
import com.timeline.vpn.model.po.HostPo;
import com.timeline.vpn.model.po.IWannaPo;
import com.timeline.vpn.model.po.RadacctState;
import com.timeline.vpn.model.vo.DnsResverItemVo;
import com.timeline.vpn.model.vo.DnsResverVo;
import com.timeline.vpn.model.vo.HostVo;
import com.timeline.vpn.model.vo.IWannaVo;
import com.timeline.vpn.model.vo.IWannnWeixinVo;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.LocationVo;
import com.timeline.vpn.model.vo.ServerVo;
import com.timeline.vpn.model.vo.StateUseVo;
import com.timeline.vpn.model.vo.VipLocationVo;
import com.timeline.vpn.service.strategy.IAppAgent;
import com.timeline.vpn.util.ArrayUtil;

/**
 * @author gqli
 * @date 2016年4月19日 下午2:56:27
 * @version V1.0
 */
public class VoBuilder {
    private static final Logger LOGGER = LoggerFactory.getLogger(VoBuilder.class);

    public static <M, I> M buildVo(I po, Class<M> m, BuildAction<I, M> action) {
        if (po != null) {
            try {
                M s = (M) m.newInstance();
                BeanUtils.copyProperties(po, s);
                if (action != null) {
                    action.action(po, s);
                }
                return s;
            } catch (Exception e) {
                LOGGER.error("", e);
            }
        }
        return null;
    }

    public static <M, I> List<M> buildListVo(List<I> poList, Class<M> m, BuildAction<I, M> action) {
        if (!CollectionUtils.isEmpty(poList)) {
            try {
                List<M> vo = ArrayUtil.newArrayList(m);
                for (I i : poList) {
                    M s = (M) m.newInstance();
                    BeanUtils.copyProperties(i, s);
                    if (action != null) {
                        action.action(i, s);
                    }
                    vo.add(s);
                }
                return vo;
            } catch (Exception e) {
                LOGGER.error("", e);
            }
        }
        return ArrayUtil.newZreoSizeArrayList(m);
    }

    public static <M, I> InfoListVo<M> buildListInfoVo(List<I> poList, Class<M> m,
            BuildAction<I, M> action) {
        InfoListVo<M> vo = new InfoListVo<M>();
        List<M> voList = buildListVo(poList, m, action);
        vo.setVoList(voList);
        vo.setHasMore(false);
        return vo;
    }


    public static ServerVo buildServerVo(String name, String pwd, Integer type,
            List<HostPo> hostList,BuildAction<HostPo, HostVo> action) {
        ServerVo vo = new ServerVo();
        vo.setName(name);
        vo.setPwd(pwd);
        vo.setType(type);
        List<HostVo> list = buildListVo(hostList, HostVo.class, action);
        vo.setHostList(list);
        return vo;
    }

    public static InfoListVo<IWannaVo> buildIWannaPageInfoVo(Page<IWannaPo> data,
            BaseQuery baseQuery) {
        String name =
                baseQuery.getUser() == null ? Constant.superMan : baseQuery.getUser().getName();
        InfoListVo<IWannaVo> page = new InfoListVo<IWannaVo>();
        List<IWannaVo> list = new ArrayList<>();
        if (!CollectionUtils.isEmpty(data)) {
            for (IWannaPo po : data) {
                list.add(buildIWannaVo(po, name));
            }
        }
        page.setVoList(list);
        page.setHasMore(data.getPageNum() < data.getPages());
        page.setPageNum(data.getPageNum() + 1);
        return page;
    }
    public static IWannnWeixinVo buildIWannaXinXVo(IWannaPo po, String name) {
      IWannnWeixinVo vo = new IWannnWeixinVo();
      BeanUtils.copyProperties(po, vo);
      return vo;
    }
    public static IWannaVo buildIWannaVo(IWannaPo po, String name) {
        IWannaVo vo = new IWannaVo();
        BeanUtils.copyProperties(po, vo);
        if(!StringUtils.isEmpty(po.getIpLocal())){
            vo.setName(vo.getName()+" - "+po.getIpLocal());
        }
        vo.setLike(StringUtils.isNotBlank(po.getLikeUsers()) && po.getLikeUsers().contains(name));
        vo.setTime(po.getCreateTime() != null ? po.getCreateTime().getTime() : 0);
        if(org.apache.commons.lang3.StringUtils.isEmpty(po.getIpLocal())) {
            vo.setWhere("来自火星");
        }else {
            vo.setWhere(po.getIpLocal());
        }
        vo.setAppName(po.getAppName().replace(Constant.NETTYPEA, "")+"用户");
        return vo;
    }

    public static <M, I> InfoListVo<M> buildPageInfoVo(Page<I> data, Class<M> clasz,
            BuildAction<I, M> action) {
        InfoListVo<M> page = buildListInfoVo(data, clasz, action);
        page.setHasMore(data.getPageNum() < data.getPages());
        page.setPageNum(data.getPageNum() + 1);
        page.setTotal(data.getTotal());
        return page; 
    }

    public static InfoListVo<DnsResverVo> buildDnsResverInfoList(List<DnsResverPo> list) {
        InfoListVo<DnsResverVo> vo = new InfoListVo<DnsResverVo>();
        List<DnsResverVo> voItemList = new ArrayList<>();
        vo.setVoList(voItemList);
        Map<String, List<DnsResverItemVo>> map = new HashMap<>();
        for (DnsResverPo po : list) {
            List<DnsResverItemVo> itemList = map.get(po.getDomain());
            if (itemList == null) {
                itemList = new ArrayList<>();
                map.put(po.getDomain(), itemList);
            }
            DnsResverItemVo item = new DnsResverItemVo();
            item.setIp(po.getIp());
            item.setTtl(po.getTtl());
            itemList.add(item);
        }
        for (Entry<String, List<DnsResverItemVo>> item : map.entrySet()) {
            voItemList.add(new DnsResverVo(item.getKey(), item.getValue()));
        }
        return vo;
    }
    public static StateUseVo buildStateUseVo(RadacctState state){
        StateUseVo vo = new StateUseVo();
        if(state!=null){
            long time = state.getAcctSessionTime();
            long h = time/(3600);
            long m = (time%(3600))/60;
            long s = (time%(3600))%60;
            vo.setTimeUse(String.format(Constant.STATE_TIME_USE, h,m,s));
            String result = "0B";
            double traffic = (state.getAcctInputOctets()+state.getAcctOutputOctets());
            double mb = traffic/1024/1024/1024;
            if(mb>0){
                result = String.format(Constant.STATE_TRAFFIC_USE,mb)+"Gb";
            }else{
                double kb = traffic/1024/1024;
                if(kb>0){
                    result = String.format(Constant.STATE_TRAFFIC_USE,kb)+"Kb";
                }else{
                    result = traffic+"B";
                }
            }
            vo.setTrafficUse(result);
        }else{
            vo.setTimeUse("0 s");
            vo.setTrafficUse("0B");
        }
        return vo;
    }

    public static interface BuildAction<I, T> {
        public void action(I i, T t);
    }

    public static <T extends IAppAgent> void buildServiceProxy(Map<String, T> serviceMap,
            Map<String, T> map) {
        for (Map.Entry<String, T> item : serviceMap.entrySet()) {
            map.put(item.getValue().getAgent(), item.getValue());
        }
        LOGGER.info("buildServiceProxy:" + map);  
    }

    public static InfoListVo<VipLocationVo> buildListVipLocationVo(
            Map<Integer, Collection<LocationVo>> map) {
        InfoListVo<VipLocationVo> vo = new InfoListVo<>();
        vo.setHasMore(false);
        vo.setPageNum(1);
        List<VipLocationVo> list = new ArrayList<>();
        for(int i=0;i<4;i++) {
            Collection<LocationVo> itemList = map.get(i);
            LocationTypeNameEnum nameType = LocationTypeNameEnum.getModelType(i);
            if(nameType==null || CollectionUtils.isEmpty(itemList)) {
                continue;
            }
            VipLocationVo vipLocationVo  = new VipLocationVo();
            vipLocationVo.setType(i);
            vipLocationVo.setCount(itemList.size());
            vipLocationVo.setList(new ArrayList<>(itemList));
            vipLocationVo.setName(nameType.getName());
            vipLocationVo.setDesc(nameType.getDesc());
            vipLocationVo.setEname(nameType.getEname());
            vipLocationVo.setEdesc(nameType.getEdesc());
            list.add(vipLocationVo);
        }
        vo.setVoList(list);
        vo.setTotal(list.size());
        return vo;
    }
}

