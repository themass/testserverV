package com.timeline.vpn.model.form;

import lombok.Data;

/**
 * 发一条弹幕的请求体（JSON）。键名就是 app 端 PostBody 的键名。
 */
@Data
public class DanmakuPostForm {
    private String clientMessageId;
    private long atMs;
    private String text;
}
