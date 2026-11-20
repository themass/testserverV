package com.timeline.vpn.service.impl;

import com.github.pagehelper.Page;
import com.github.pagehelper.PageHelper;
import com.timeline.vpn.VoBuilder;
import com.timeline.vpn.common.exception.BusinessException;
import com.timeline.vpn.dao.db.SubtitleDao;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.PageBaseParam;
import com.timeline.vpn.model.po.SubtitlePo;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.SubtitleContentVo;
import com.timeline.vpn.model.vo.SubtitleVo;
import com.timeline.vpn.service.DataSubtitleService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * @author gqli
 * @date 2026年11月21日
 * @version V1.0
 */
@Service
public class DataSubtitleServiceImpl implements DataSubtitleService {
    @Autowired
    private SubtitleDao subtitleDao;

    /**
     * 分页语义逐字照抄 DataVideoServiceImpl.getVideoPage：start/limit 原样进
     * PageHelper.startPage，不做任何换算，保证 app 端翻页跟老接口完全一致。
     */
    @Override
    public InfoListVo<SubtitleVo> getSubtitlePage(BaseQuery baseQuery, PageBaseParam param,
            long videoId) {
        PageHelper.startPage(param.getStart(), param.getLimit());
        List<SubtitlePo> list = subtitleDao.getListByVideo(videoId);
        return VoBuilder.buildPageInfoVo((Page<SubtitlePo>) list, SubtitleVo.class,
                new VoBuilder.BuildAction<SubtitlePo, SubtitleVo>() {
                    @Override
                    public void action(SubtitlePo i, SubtitleVo t) {
                        // id/title/lang/format/size 由 BeanUtils 从 PO 同名属性拷过来；
                        // 这里刻意什么都不做——加字段就等于把 content 带出去的风险。
                    }
                });
    }

    @Override
    public SubtitleContentVo getSubtitleContent(BaseQuery baseQuery, long id) {
        SubtitlePo po = subtitleDao.getContent(id);
        if (po == null) {
            throw new BusinessException("字幕不存在");
        }
        return VoBuilder.buildVo(po, SubtitleContentVo.class, null);
    }

}
