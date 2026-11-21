package com.timeline.vpn.service;

import com.timeline.vpn.model.vo.TimelinePostVo;
import com.timeline.vpn.model.vo.TimelineWindowVo;

/**
 * 通用弹幕（时间轴域）。契约对齐 app 端 HttpDanmakuSource：分窗拉取、clientMsgId 幂等发送、作者软删撤回。
 *
 * <p>参数校验按层分工：URL 形状与文本长度这类「请求形」校验在 controller 做（errno 11002），
 * 这里只管业务规则——幂等、限频、存在性、归属，出错抛 BusinessException（errno 11003，文案可展示）。
 */
public interface DataDanmakuService {

    /** 取 [startMs, endMs) 窗口内未撤回的弹幕，id 游标分页，单页最多 limit 条。 */
    TimelineWindowVo getWindow(String namespace, String contentId, String editionId,
            long startMs, long endMs, Long cursor, int limit);

    /**
     * 发一条弹幕。同一 (namespace, contentId, editionId, userId, clientMsgId) 重复进来返回同一条定稿，
     * 不再落库——客户端重试因此永远不需要知道自己是第几次。
     */
    TimelinePostVo post(String namespace, String contentId, String editionId,
            long userId, String authorName, String clientMessageId, long atMs, String text);

    /** 撤回：只认作者本人。不存在、已撤回、不是本人，都抛 BusinessException。 */
    void retract(long commentId, long userId);
}
