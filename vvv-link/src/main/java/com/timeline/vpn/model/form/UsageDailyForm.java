package com.timeline.vpn.model.form;

/** 客户端上报的每日使用汇总：log 是 JSON 数组字符串，见客户端 UsageReport.Item。 */
public class UsageDailyForm {
    private String log;

    public String getLog() { return log; }
    public void setLog(String log) { this.log = log; }
}
