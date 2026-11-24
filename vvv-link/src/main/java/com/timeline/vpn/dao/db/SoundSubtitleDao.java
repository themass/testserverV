package com.timeline.vpn.dao.db;

import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.SoundItems;
import com.timeline.vpn.model.po.SoundSubtitlePo;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 声音馆歌词轨（vpn.sound_subtitle）。分工照 SubtitleDao：
 * getListBySoundItem 取列表列（不含 content），getContent 只取正文列。
 * 额外的 claim/更新列服务按需生成（genStatus 状态机）。
 */
@Mapper
public interface SoundSubtitleDao extends BaseDBDao<SoundSubtitlePo> {
    /** 列表：不含 content，size 用 LENGTH(content) 现算。 */
    List<SoundSubtitlePo> getListBySoundItem(@Param("soundItemId") long soundItemId);

    /** 正文：单条按 id 取，回 id/content/format/lang。 */
    SoundSubtitlePo getContent(@Param("id") long id);

    /** 按条目取一行（claim/状态判定时用），不含 content。 */
    SoundSubtitlePo getBySoundItem(@Param("soundItemId") long soundItemId);

    /** 补量 job：还没有任何歌词轨的声音条目（不含大字段）。 */
    List<SoundItems> listItemsWithoutTrack(@Param("limit") int limit);

    int insertRunning(SoundSubtitlePo po);

    int updateGenStatus(@Param("id") long id, @Param("genStatus") String genStatus);

    /** 生成成功后一次性写正文+指纹+引擎+ready。 */
    int updateGenerated(@Param("id") long id, @Param("content") String content,
            @Param("sourceFileHash") String sourceFileHash, @Param("engine") String engine,
            @Param("genStatus") String genStatus);
}
