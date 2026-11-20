package com.timeline.vpn.model.vo;

import lombok.Data;

/**
 * 字幕列表项（/api/video/subtitle/items.json）。
 *
 * <p>刻意没有 content 字段：整份字幕文本只走 item.json 单条下发，列表绝不携带。
 */
@Data
public class SubtitleVo {
    private long id;
    private String title;
    /** 语言标记，如 zh / en */
    private String lang;
    /** srt / vtt */
    private String format;
    /** content 字节数，客户端据此估算下载量 */
    private long size;
}
