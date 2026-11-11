package com.timeline.vpn.model.po;

import java.util.Date;

/**
 * vpn.bug_report 的一行：用户主动上报的一条问题。
 * <p>
 * 对应客户端设置页的「上报问题」：用户读完弹窗里的收集清单、点了同意才会走到这里。
 */
public class BugReportPo {
    private Long id;
    private Long userId;
    private String devId;
    private String userIp;
    private String version;
    private String label;
    private String fileName;
    private int fileBytes;
    private String content;
    private boolean truncated;
    private Date createdAt;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getDevId() {
        return devId;
    }

    public void setDevId(String devId) {
        this.devId = devId;
    }

    public String getUserIp() {
        return userIp;
    }

    public void setUserIp(String userIp) {
        this.userIp = userIp;
    }

    public String getVersion() {
        return version;
    }

    public void setVersion(String version) {
        this.version = version;
    }

    public String getLabel() {
        return label;
    }

    public void setLabel(String label) {
        this.label = label;
    }

    public String getFileName() {
        return fileName;
    }

    public void setFileName(String fileName) {
        this.fileName = fileName;
    }

    public int getFileBytes() {
        return fileBytes;
    }

    public void setFileBytes(int fileBytes) {
        this.fileBytes = fileBytes;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public boolean isTruncated() {
        return truncated;
    }

    public void setTruncated(boolean truncated) {
        this.truncated = truncated;
    }

    public Date getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Date createdAt) {
        this.createdAt = createdAt;
    }
}
