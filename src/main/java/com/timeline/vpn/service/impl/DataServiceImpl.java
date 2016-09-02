package com.timeline.vpn.service.impl;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.timeline.vpn.dao.db.RecommendDao;
import com.timeline.vpn.dao.db.VersionDao;
import com.timeline.vpn.model.po.RecommendPo;
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
public class DataServiceImpl implements DataService{
    @Autowired
    private VersionDao versionDao;
    @Autowired
    private RecommendDao recommendDao;

    @Override
    public InfoListVo<RecommendVo> getRecommendList() {
        List<RecommendPo> poList = recommendDao.getAll();
        List<RecommendPo> poList1 = recommendDao.getAll();
        List<RecommendPo> poList2 = recommendDao.getAll();
        List<RecommendPo> poList3 = recommendDao.getAll();
        poList.addAll(poList1);
        poList.addAll(poList2);
        poList.addAll(poList3);
        InfoListVo<RecommendVo> vo = VoBuilder.buildListInfoVo(poList,RecommendVo.class);
        vo.setHasMore(false);
        return vo;
    }
    @Override
    public VersionInfoVo getVersion(String platform) {
        return VoBuilder.buildVo(versionDao.getLast(platform),VersionInfoVo.class);
    }
    
}

