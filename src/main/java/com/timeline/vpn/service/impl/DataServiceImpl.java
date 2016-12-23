package com.timeline.vpn.service.impl;

import java.util.Date;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.github.pagehelper.Page;
import com.github.pagehelper.PageHelper;
import com.timeline.vpn.Constant;
import com.timeline.vpn.dao.db.IWannaDao;
import com.timeline.vpn.dao.db.RecommendDao;
import com.timeline.vpn.dao.db.VersionDao;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.PageBaseParam;
import com.timeline.vpn.model.po.IWannaPo;
import com.timeline.vpn.model.po.RecommendPo;
import com.timeline.vpn.model.vo.IWannaVo;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.RecommendVo;
import com.timeline.vpn.model.vo.VersionInfoVo;
import com.timeline.vpn.model.vo.VoBuilder;
import com.timeline.vpn.service.DataService;
import com.timeline.vpn.web.common.CommonHandlerExceptionResolver;

/**
 * @author gqli
 * @date 2016年3月10日 下午4:45:36
 * @version V1.0
 */
@Service
public class DataServiceImpl implements DataService {
    private static final Logger LOGGER =
            LoggerFactory.getLogger(DataServiceImpl.class);

    @Autowired
    private VersionDao versionDao;
    @Autowired
    private RecommendDao recommendDao;
    @Autowired
    private IWannaDao iWannaDao;

    @Override
    public InfoListVo<RecommendVo> getRecommendPage(PageBaseParam param) {
        PageHelper.startPage(param.getStart(), param.getLimit());
        List<RecommendPo> poList = recommendDao.getAll();
        return VoBuilder.buildPageInfoVo((Page<RecommendPo>) poList, RecommendVo.class);
    }

    @Override
    public VersionInfoVo getVersion(String platform) {
        return VoBuilder.buildVo(versionDao.getLast(platform), VersionInfoVo.class);
    }

    @Override
    public InfoListVo<IWannaVo> getIwannaPage(BaseQuery baseQuery, PageBaseParam param) {
        PageHelper.startPage(param.getStart(), param.getLimit());
        Page<IWannaPo> data = (Page<IWannaPo>) iWannaDao.getPage();
        return VoBuilder.buildIWannaPageInfoVo(data, baseQuery);
    }

    @Override
    public IWannaVo addIwanna(BaseQuery baseQuery, String content) {
        LOGGER.info("addIwanna->"+content);
        IWannaPo po = new IWannaPo();
        po.setContent(content);
        po.setCreateTime(new Date());
        po.setLikes(0);
        po.setLikeUsers(Constant.superMan);
        po.setName(baseQuery.getUser().getName());
        iWannaDao.insert(po);
        return VoBuilder.buildIWannaVo(po, baseQuery.getUser().getName());
    }

    @Override
    public void addIwannaLike(BaseQuery baseQuery, long id) {
        IWannaPo po = iWannaDao.get(id);
        po.setLikes(po.getLikes() + 1);
        if (baseQuery.getUser()!=null && !po.getLikeUsers().contains(baseQuery.getUser().getName())) {
            po.setLikeUsers(po.getLikeUsers() + "," + baseQuery.getUser().getName());
        }
        iWannaDao.like(po);

    }

}

