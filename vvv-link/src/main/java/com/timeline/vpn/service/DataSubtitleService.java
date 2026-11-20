package com.timeline.vpn.service;

import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.PageBaseParam;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.SubtitleContentVo;
import com.timeline.vpn.model.vo.SubtitleVo;

/**
 * 视频字幕。列表不带正文，正文单条取。
 */
public interface DataSubtitleService {

    InfoListVo<SubtitleVo> getSubtitlePage(BaseQuery baseQuery, PageBaseParam param, long videoId);

    SubtitleContentVo getSubtitleContent(BaseQuery baseQuery, long id);

}
