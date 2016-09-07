package com.timeline.vpn.service.impl;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.databind.deser.Deserializers.Base;
import com.github.pagehelper.Page;
import com.github.pagehelper.PageHelper;
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

/**
 * @author gqli
 * @date 2016年3月10日 下午4:45:36
 * @version V1.0
 */
@Service
public class DataServiceImpl implements DataService {
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
        return VoBuilder.buildIWannaPageInfoVo(data, baseQuery.getUser().getName());
    }

    @Override
    public IWannaVo addIwanna(BaseQuery baseQuery, String content) {
        IWannaPo po = new IWannaPo();
        po.setContent(content);
        po.setCreateTime(new Date());
        po.setLikes(0);
        po.setLikeUsers("8>");
        po.setName(baseQuery.getUser().getName());
        iWannaDao.insert(po);
        return VoBuilder.buildIWannaVo(po, baseQuery.getUser().getName());
    }

    @Override
    public void addIwannaLike(BaseQuery baseQuery, long id) {
        IWannaPo po = iWannaDao.get(id);
        po.setLikes(po.getLikes() + 1);
        if (!po.getLikeUsers().contains(baseQuery.getUser().getName())) {
            po.setLikeUsers(po.getLikeUsers() + "," + baseQuery.getUser().getName());
        }
        iWannaDao.like(po);

    }

}

