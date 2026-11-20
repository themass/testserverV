package com.timeline.vpn.dao.db;

import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.SubtitlePo;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 视频字幕（vpn.video_subtitle）。
 *
 * <p>两条查询分工明确：getListByVideo 取列表列（不含 content），getContent 只取正文列。
 */
@Mapper
public interface SubtitleDao extends BaseDBDao<SubtitlePo> {
    List<SubtitlePo> getListByVideo(@Param("videoId") long videoId);

    SubtitlePo getContent(@Param("id") long id);
}
