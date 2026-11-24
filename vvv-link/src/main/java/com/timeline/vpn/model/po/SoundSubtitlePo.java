package com.timeline.vpn.model.po;

import lombok.Data;

/**
 * 声音馆歌词轨（表 vpn.sound_subtitle，DDL sql/2026112400_sound_subtitle.sql）。
 *
 * <p>一条声音条目 MVP 只有一轨（表上 UNIQUE(soundItemId)）。列表查询不 select content
 * （见 SoundSubtitleMapper.xml），走列表时 content 恒为 null——不是 bug，是刻意的。
 * size 不是列：列表 SQL 里用 LENGTH(content) 现算，供客户端估算下载量。
 * createTime 是 BIGINT（epoch 毫秒），跟本特性新表口径一致。
 */
@Data
public class SoundSubtitlePo {
    private long id;
    /** 归属声音条目：vpn.sounditems.id */
    private long soundItemId;
    private String title;
    /** 语言标记，如 zh / en */
    private String lang;
    /** MVP 只产 srt */
    private String format;
    /** 整份 SRT 正文，只在 item.json 单条查询里取 */
    private String content;
    /** 生成时音频 URL 的 SHA-256：换文件自动失效 */
    private String sourceFileHash;
    /** pending / running / ready / failed */
    private String genStatus;
    /** 生成引擎标记，如 deepgram:nova-2-general */
    private String engine;
    private int enabled;
    /** 非列：列表 SQL 里 LENGTH(content) 别名而来 */
    private long size;
    private long createTime;
}
