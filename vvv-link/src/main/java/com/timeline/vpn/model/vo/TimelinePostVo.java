package com.timeline.vpn.model.vo;

import lombok.Data;

/**
 * 发送成功的 data：定稿的那一条。键名对齐 app 端 EnvelopeData：comment。
 */
@Data
public class TimelinePostVo {
    private TimelineCommentVo comment;
}
