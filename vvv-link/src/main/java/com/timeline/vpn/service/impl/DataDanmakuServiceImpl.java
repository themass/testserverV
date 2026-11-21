package com.timeline.vpn.service.impl;

import com.timeline.vpn.common.exception.BusinessException;
import com.timeline.vpn.dao.db.DanmakuCommentDao;
import com.timeline.vpn.model.po.DanmakuCommentPo;
import com.timeline.vpn.model.vo.TimelineCommentVo;
import com.timeline.vpn.model.vo.TimelinePostVo;
import com.timeline.vpn.model.vo.TimelineWindowVo;
import com.timeline.vpn.service.DataDanmakuService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

/**
 * @author gqli
 * @date 2026年11月22日
 * @version V1.0
 */
@Service
public class DataDanmakuServiceImpl implements DataDanmakuService {

    /** 限频：窗口时长与条数上限（对所有用户的全局口径，先粗后细）。 */
    private static final long RATE_WINDOW_MS = 60_000L;
    private static final int RATE_LIMIT = 10;

    @Autowired
    private DanmakuCommentDao danmakuCommentDao;

    @Override
    public TimelineWindowVo getWindow(String namespace, String contentId, String editionId,
            long startMs, long endMs, Long cursor, int limit) {
        List<DanmakuCommentPo> list = danmakuCommentDao.listWindow(namespace, contentId, editionId,
                startMs, endMs, cursor, limit);
        List<TimelineCommentVo> comments = new ArrayList<>(list.size());
        for (DanmakuCommentPo po : list) {
            comments.add(toVo(po));
        }
        TimelineWindowVo vo = new TimelineWindowVo();
        vo.setComments(comments);
        // 满页即可能有下一页：游标就是页尾 id。少一页则收口，客户端下一跳最多空跑一次。
        if (list.size() >= limit) {
            vo.setNextCursor(String.valueOf(list.get(list.size() - 1).getId()));
        }
        return vo;
    }

    @Override
    public TimelinePostVo post(String namespace, String contentId, String editionId,
            long userId, String authorName, String clientMessageId, long atMs, String text) {
        // 先查幂等命中：重试不该再吃限频和唯一键冲突
        DanmakuCommentPo exist = danmakuCommentDao.getByClientMsg(namespace, contentId, editionId,
                userId, clientMessageId);
        if (exist != null) {
            return wrap(exist);
        }
        int recent = danmakuCommentDao.countRecent(userId,
                new Date(System.currentTimeMillis() - RATE_WINDOW_MS));
        if (recent >= RATE_LIMIT) {
            throw new BusinessException("发送太快，缓一缓再发");
        }
        DanmakuCommentPo po = new DanmakuCommentPo();
        po.setNamespace(namespace);
        po.setContentId(contentId);
        po.setEditionId(editionId);
        po.setAtMs(atMs);
        po.setContent(text);
        po.setUserId(userId);
        po.setAuthorName(authorName == null ? "" : authorName);
        po.setClientMsgId(clientMessageId);
        try {
            danmakuCommentDao.insert(po);
        } catch (DuplicateKeyException e) {
            // 并发重试撞了唯一键：赢家已把同一条落库，直接把它当定稿回
            DanmakuCommentPo winner = danmakuCommentDao.getByClientMsg(namespace, contentId, editionId,
                    userId, clientMessageId);
            if (winner == null) {
                throw new BusinessException("弹幕写入冲突，请重试");
            }
            return wrap(winner);
        }
        return wrap(po);
    }

    @Override
    public void retract(long commentId, long userId) {
        DanmakuCommentPo po = danmakuCommentDao.getById(commentId);
        if (po == null || po.getDeleted() == 1) {
            throw new BusinessException("弹幕不存在或已撤回");
        }
        if (po.getUserId() != userId) {
            throw new BusinessException("只能撤回自己的弹幕");
        }
        danmakuCommentDao.softDelete(commentId, userId);
    }

    private TimelinePostVo wrap(DanmakuCommentPo po) {
        TimelinePostVo vo = new TimelinePostVo();
        vo.setComment(toVo(po));
        return vo;
    }

    private TimelineCommentVo toVo(DanmakuCommentPo po) {
        TimelineCommentVo vo = new TimelineCommentVo();
        vo.setId(po.getId());
        vo.setAtMs(po.getAtMs());
        vo.setText(po.getContent());
        vo.setAuthor(po.getAuthorName());
        return vo;
    }
}
