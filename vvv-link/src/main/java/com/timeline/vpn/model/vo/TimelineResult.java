package com.timeline.vpn.model.vo;

import lombok.Data;

/**
 * 时间轴域的返回信封：{errno, data, error}，形状对齐 app 端 HttpDanmakuSource.Envelope。
 *
 * <p>刻意不用 {@link JsonResult}：它的 data 在非测试环境会被 AES 加密（app.isTest() 判定），
 * 且 getData() 依赖 HostFilter 注入的 DevAppContext——而 HostFilter 与全部拦截器只挂在 *.json 上，
 * 弹幕接口是不带 .json 的 REST 路径，套 JsonResult 会当场 NPE。
 */
@Data
public class TimelineResult {
    private int errno;
    private Object data;
    private String error;

    public static TimelineResult ok(Object data) {
        TimelineResult result = new TimelineResult();
        result.errno = 0;
        result.data = data;
        return result;
    }

    public static TimelineResult fail(int errno, String error) {
        TimelineResult result = new TimelineResult();
        result.errno = errno;
        result.error = error;
        return result;
    }
}
