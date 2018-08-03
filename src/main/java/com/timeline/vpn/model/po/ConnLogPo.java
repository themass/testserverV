package com.timeline.vpn.model.po;
/**
 * @author gqli
 * @date 2018年8月3日 下午2:09:11
 * @version V1.0
 */
public class ConnLogPo {
  private String name;
  private String host;
  private String userIp;
  private int status;
  private String time;
  public String getName() {
    return name;
  }
  public void setName(String name) {
    this.name = name;
  }
  public String getHost() {
    return host;
  }
  public void setHost(String host) {
    this.host = host;
  }
  public String getUserIp() {
    return userIp;
  }
  public void setUserIp(String userIp) {
    this.userIp = userIp;
  }
  public int getStatus() {
    return status;
  }
  public void setStatus(int status) {
    this.status = status;
  }
  public String getTime() {
    return time;
  }
  public void setTime(String time) {
    this.time = time;
  }
  
}

