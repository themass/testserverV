package com.timeline.vpn.model.form;

import com.sun.tools.javac.util.List;
import com.timeline.vpn.model.po.ConnLogPo;

/**
 * @author gqli
 * @date 2018年8月3日 下午2:10:21
 * @version V1.0
 */
public class ConnLogForm {
  private List<ConnLogPo> log;

  public List<ConnLogPo> getLog() {
    return log;
  }

  public void setLog(List<ConnLogPo> log) {
    this.log = log;
  }
  
}

