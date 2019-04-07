package com.timeline.vpn.service.job.reload;

import java.util.Date;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import com.timeline.vpn.dao.db.LockJobDao;
import com.timeline.vpn.metric.Measure;
import com.timeline.vpn.metric.Metrics;
import com.timeline.vpn.model.po.LockJobPo;
import com.timeline.vpn.service.job.ReloadJob;
import com.timeline.vpn.util.DateTimeUtils;
import com.timeline.vpn.util.IpLocalUtil;

/**
 * @author gqli
 * @Description: 预约原信息reload类，jvm内存存储
 * @date 2016年9月26日 下午2:47:21
 */
@Repository
public class HostIpMonitor extends ReloadJob {
  private static final Logger LOGGER = LoggerFactory.getLogger(HostIpMonitor.class);
   @Autowired
   private LockJobDao lockJobDao;
    public void reload() {
      LockJobPo po = new LockJobPo();
      po.setJobName("HostIpMonitor");
      String time = DateTimeUtils.formatDate(DateTimeUtils.YYYY_MM_DDHH_MM,new Date());
      time = time.substring(0, time.length()-1);
      po.setJobTime(time);
      po.setIp(IpLocalUtil.getHostIp());
     try {
      if(lockJobDao.insert(po)>0) {
        for(String ip :HostCheck.allIp()){
          Metrics.count(Measure.vpn_connect_live_all.name(),"IP-"+ip);
        }
        LOGGER.info("HostIpMonitor  size="+HostCheck.allIp().size());
      }
     }catch (Exception e) {
        
    }
    }
}
