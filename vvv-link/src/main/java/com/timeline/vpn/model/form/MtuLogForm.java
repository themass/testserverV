package com.timeline.vpn.model.form;

/** 客户端上报的 MTU 记录：log 是 JSON 数组字符串。 */
public class MtuLogForm {
    private String log;

    public String getLog() { return log; }
    public void setLog(String log) { this.log = log; }
}
