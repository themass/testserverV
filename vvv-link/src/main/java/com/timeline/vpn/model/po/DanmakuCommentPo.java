package com.timeline.vpn.model.po;

import lombok.Data;

import java.util.Date;

/**
 * 通用弹幕（表 vpn.danmaku_comment）。
 *
 * <p>一条弹幕挂在 (namespace, contentId, editionId) 定位的时间轴上，atMs 是媒资播放时钟的毫秒锚点。
 * clientMsgId 与 userId 组成唯一键：客户端重试带着同一个 clientMsgId 再来，只会命中同一条定稿。
 */
@Data
public class DanmakuCommentPo {
    private long id;
    /** 时间轴命名空间，如 local */
    private String namespace;
    /** 媒资稳定 id（客户端 key） */
    private String contentId;
    /** 同一媒资的轴版本，如 v1 */
    private String editionId;
    /** 弹幕锚点：媒资播放时钟毫秒 */
    private long atMs;
    /** 弹幕文本 */
    private String content;
    /** 发送者 vpn.user.id */
    private long userId;
    /** 发送者昵称快照 */
    private String authorName;
    /** 客户端幂等 id */
    private String clientMsgId;
    /** 1=作者已撤回 */
    private int deleted;
    private Date createTime;
}
