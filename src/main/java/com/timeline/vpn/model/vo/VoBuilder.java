package com.timeline.vpn.model.vo;

import java.util.List;

import org.apache.commons.lang.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.BeanUtils;
import org.springframework.util.CollectionUtils;

import com.timeline.vpn.model.po.HostPo;
import com.timeline.vpn.model.po.ServerPo;
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

    public static <M> InfoListVo<M> buildListInfoVo(List<M> voList) {
        InfoListVo<M> vo = new InfoListVo<M>();
        vo.setVoList(voList);
        vo.setHasMore(false);
        return vo;
    }

    public static ServerVo buildServerVo(ServerPo serverPo, List<HostPo> hostList, long remainingTime) {
        ServerVo vo = new ServerVo();
        BeanUtils.copyProperties(serverPo, vo);
        
        List<HostVo> list = buildListVo(hostList,HostVo.class);
        for (HostVo hostVo : list) {
            hostVo.setCert(StringUtils.replace(hostVo.getCert(), "\\n", "\n").replaceAll(" ", ""));
        }
        vo.setHostList(list);
        vo.setRemainingTime(remainingTime);
        return vo;
    }
}

