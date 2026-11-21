package com.timeline.vpn.dao.db;

import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.DanmakuCommentPo;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.Date;
import java.util.List;

/**
 * 通用弹幕（vpn.danmaku_comment）。
 *
 * <p>查询分工：listWindow 按时间窗 + 游标分页取未撤回的弹幕；getByClientMsg 服务幂等重发；
 * softDelete 只按 (id, userId) 命中，天然挡住撤别人的弹幕；countRecent 给限频用。
 */
@Mapper
public interface DanmakuCommentDao extends BaseDBDao<DanmakuCommentPo> {

    /**
     * 窗口分页：atMs ∈ [startMs, endMs)，id &gt; cursor（null 表示从头），按 id 升序取 limit 条。
     * 游标用 id 而不是 offset：窗口刷新和翻页共用同一语义，插入的新弹幕不会把老页挤重复。
     */
    List<DanmakuCommentPo> listWindow(@Param("namespace") String namespace,
            @Param("contentId") String contentId, @Param("editionId") String editionId,
            @Param("startMs") long startMs, @Param("endMs") long endMs,
            @Param("cursor") Long cursor, @Param("limit") int limit);

    DanmakuCommentPo getByClientMsg(@Param("namespace") String namespace,
            @Param("contentId") String contentId, @Param("editionId") String editionId,
            @Param("userId") long userId, @Param("clientMsgId") String clientMsgId);

    DanmakuCommentPo getById(@Param("id") long id);

    /** 撤回：软删，且只允许作者本人（userId 进 where）。返回 1 表示成功。 */
    int softDelete(@Param("id") long id, @Param("userId") long userId);

    /** 限频：该用户 createTime ≥ since 的弹幕条数。 */
    int countRecent(@Param("userId") long userId, @Param("since") Date since);
}
