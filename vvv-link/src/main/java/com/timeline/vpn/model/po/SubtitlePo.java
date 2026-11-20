package com.timeline.vpn.model.po;

import lombok.Data;

import java.util.Date;

/**
 * 视频字幕（表 vpn.video_subtitle）。
 *
 * <p>content 只在 {@code /api/video/subtitle/item.json} 单条查询里取，列表查询不 select 这一列，
 * 所以走列表时这里 content 恒为 null——不是 bug，是刻意的。
 */
@Data
public class SubtitlePo {
    private long id;
    /** 归属视频：vpn.videoitems_1.id */
    private long videoId;
    private String title;
    /** 语言标记，如 zh / en */
    private String lang;
    /** srt / vtt */
    private String format;
    /** content 字节数 */
    private long size;
    private String content;
    private int enabled;
    private Date createTime;
    private Date updateTime;
}
