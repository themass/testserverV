package com.timeline.vpn.service.job.reload;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Repository;

import com.timeline.vpn.metric.Measure;
import com.timeline.vpn.metric.Metrics;
import com.timeline.vpn.service.job.ReloadJob;

/**
 * @author gqli
 * @Description: 预约原信息reload类，jvm内存存储
 * @date 2016年9月26日 下午2:47:21
 */
@Repository
public class HostIpMonitor extends ReloadJob {
  private static final Logger LOGGER = LoggerFactory.getLogger(HostIpMonitor.class);

    public void reload() {
        for(String ip :HostCheck.allIp()){
          Metrics.count(Measure.vpn_connect_live_all.name(),ip);
        }
        LOGGER.info("HostIpMonitor  size="+HostCheck.allIp().size());
        
    }
}
