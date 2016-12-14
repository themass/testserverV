package com.timeline.vpn.model.vo;

import java.util.ArrayList;
import java.util.List;

import org.apache.commons.lang.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.BeanUtils;
import org.springframework.util.CollectionUtils;

import com.github.pagehelper.Page;
import com.timeline.vpn.Constant;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.po.HostPo;
import com.timeline.vpn.model.po.IWannaPo;
import com.timeline.vpn.util.ArrayUtil;

/**
 * @author gqli
 * @date 2016年4月19日 下午2:56:27
 * @version V1.0
 */
public class VoBuilder {
    private static final Logger LOGGER = LoggerFactory.getLogger(VoBuilder.class);

    public static <M, I> M buildVo(I po, Class<M> m) {
        if (po != null) {
            try {
                M s = (M) m.newInstance();
                BeanUtils.copyProperties(po, s);
                return s;
            } catch (Exception e) {
                LOGGER.error("", e);
            }
        }
        return null;
    }

    public static <M, I> List<M> buildListVo(List<I> poList, Class<M> m) {
        if (!CollectionUtils.isEmpty(poList)) {
            try {
                List<M> vo = ArrayUtil.newArrayList(m);
                for (I i : poList) {
                    M s = (M) m.newInstance();
                    BeanUtils.copyProperties(i, s);
                    vo.add(s);
                }
                return vo;
            } catch (Exception e) {
                LOGGER.error("", e);
            }
        }
        return ArrayUtil.newZreoSizeArrayList(m);
    }

    public static <M, I> InfoListVo<M> buildListInfoVo(List<I> poList, Class<M> m) {
        InfoListVo<M> vo = new InfoListVo<M>();
        List<M> voList = buildListVo(poList, m);
        vo.setVoList(voList);
        vo.setHasMore(false);
        return vo;
    }


    public static ServerVo buildServerVo(String name,String pwd,Integer type, List<HostPo> hostList) {
        ServerVo vo = new ServerVo();
        vo.setName(name);
        vo.setPwd(pwd);
        vo.setType(type);
        List<HostVo> list = buildListVo(hostList, HostVo.class);
        vo.setHostList(list);
        return vo;
    }

    public static InfoListVo<IWannaVo> buildIWannaPageInfoVo(Page<IWannaPo> data, BaseQuery baseQuery) {
        String name = baseQuery.getUser()==null?Constant.superMan:baseQuery.getUser().getName();
        InfoListVo<IWannaVo> page = new InfoListVo<IWannaVo>();
        List<IWannaVo> list = new ArrayList<>();
        if (!CollectionUtils.isEmpty(data)) {
            for (IWannaPo po : data) {
                list.add(buildIWannaVo(po,name));
            }
        }
        page.setVoList(list);
        page.setHasMore(data.getPageNum() < data.getPages());
        page.setPageNum(data.getPageNum() + 1);
        return page;
    }
    public static IWannaVo buildIWannaVo(IWannaPo po,String name){
        IWannaVo vo = new IWannaVo();
        BeanUtils.copyProperties(po, vo);
        vo.setLike(StringUtils.isNotBlank(po.getLikeUsers())
                && po.getLikeUsers().contains(name));
        vo.setTime(po.getCreateTime()!=null?po.getCreateTime().getTime():0);
        return vo;
    }
    public static <M, I> InfoListVo<M> buildPageInfoVo(Page<I> data, Class<M> clasz) {
        InfoListVo<M> page = buildListInfoVo(data, clasz);
        page.setHasMore(data.getPageNum() < data.getPages());
        page.setPageNum(data.getPageNum() + 1);
        return page;
    }
}

