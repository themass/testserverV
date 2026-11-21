package com.timeline.vpn.model.vo;

import lombok.Data;

import java.util.List;

/**
 * 一次窗口拉取的 data：弹幕页 + 游标。键名对齐 app 端 EnvelopeData：comments / nextCursor。
 */
@Data
public class TimelineWindowVo {
    private List<TimelineCommentVo> comments;
    /** 还有下一页时的游标（上一页最后一条的 id）；null 表示取完 */
    private String nextCursor;
}
