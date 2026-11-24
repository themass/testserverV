package com.timeline.vpn.model.vo;

import lombok.Data;

/**
 * 歌词正文（GET /api/sound/subtitle/item.json）。
 *
 * <p>契约 sound-lyrics-contract §2 Phase 1：{id, content, format, lang}——比视频字幕的
 * SubtitleContentVo 多带 format/lang，端上 LocalSubtitleTrack 按 format 选解析器。
 */
@Data
public class SoundSubtitleContentVo {
    private long id;
    /** 整份 SRT 文本，JSON 信封下发（客户端 AES 链路只覆盖 JsonResult） */
    private String content;
    private String format;
    private String lang;
}
