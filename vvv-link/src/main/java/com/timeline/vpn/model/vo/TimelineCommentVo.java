package com.timeline.vpn.model.vo;

import lombok.Data;

/**
 * 一条弹幕对外的样子。键名就是 app 端 HttpDanmakuSource 解析的键名：id / atMs / text / author。
 */
@Data
public class TimelineCommentVo {
    private long id;
    /** 媒资播放时钟毫秒 */
    private long atMs;
    private String text;
    /** 发送者昵称；自己发的由 app 端显示成「我」，服务端只管如实回 */
    private String author;
}
