package com.timeline.vpn.service.job;

import com.timeline.vpn.service.job.reload.*;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.beans.factory.annotation.Autowired;

@Component
public class ScheduledTasks {

    @Autowired
    private HostIpMonitor hostIpMonitor;

    @Autowired
    private DnsCache dnsCache;

    @Autowired
    private HostCheck hostCheck;

    @Autowired
    private DeleInvalidAcc deleInvalidAcc;

    @Autowired
    private FileIpCache fileIpCache;

    @Autowired
    private ZhIpCache zhIpCache;

    @Autowired
    private Score3Calculation score3Calculation;

    @Autowired
    private HostIpCacheV2 hostIpCacheV2;

    // Running every 8 minutes
    @Scheduled(cron = "0 0/8 * ? * *")
    public void hostIpMonitorExecute() {
        hostIpMonitor.execute();
    }

    // Running every hour
    @Scheduled(cron = "0 0 * ? * *")
    public void dnsCacheExecute() {
        dnsCache.execute();
    }

    // Running every minute
    @Scheduled(cron = "0 * * ? * *")
    public void hostCheckExecute() {
        hostCheck.execute();
    }

    // Running every hour
    @Scheduled(cron = "0 0 * ? * *")
    public void deleInvalidAccExecute() {
        deleInvalidAcc.execute();
    }
    // Running at the 1st minute of every hour
    @Scheduled(cron = "0 1 * ? * *")
    public void fileIpCacheExecute() {
        fileIpCache.execute();
    }

    // Running every hour
    @Scheduled(cron = "0 0 * ? * *")
    public void zhIpCacheExecute() {
        zhIpCache.execute();
    }

    // Running at 3 am every day
    @Scheduled(cron = "0 0 3 ? * *")
    public void score3CalculationExecute() {
        score3Calculation.execute();
    }

    // Running every minute
    @Scheduled(cron = "0 * * ? * *")
    public void hostIpCacheV2Execute() {
        hostIpCacheV2.execute();
    }
}