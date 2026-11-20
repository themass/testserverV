package com.timeline.vpn.model.vo;

import lombok.Data;

/**
 * 字幕正文（/api/video/subtitle/item.json）：整份 SRT/VTT 文本，JSON 信封下发
 * （客户端 AES 解密链路只覆盖 JsonResult，不能返回裸文件流）。
 */
@Data
public class SubtitleContentVo {
    private long id;
    private String content;
}
