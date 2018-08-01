package com.timeline.vpn.service.job.reload;

import java.util.Date;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import com.timeline.vpn.dao.db.LockJobDao;
import com.timeline.vpn.dao.db.UserDao;
import com.timeline.vpn.model.po.LockJobPo;
import com.timeline.vpn.service.job.ReloadJob;
import com.timeline.vpn.util.DateTimeUtils;
import com.timeline.vpn.util.IpLocalUtil;

/**
 * @author gqli
 * @date 2017年6月2日 下午9:35:47
 * @version V1.0
 */
@Component
public class Score3Calculation extends ReloadJob{
    private static final Logger LOGGER = LoggerFactory.getLogger(Score3Calculation.class);
    @Autowired
    private UserDao userDao;
    @Autowired
    private LockJobDao lockJobDao;

    @Override
    @Transactional
    public void reload() {
        LockJobPo po = new LockJobPo(); 
        po.setJobName("Score3Calculation");
        po.setJobTime(DateTimeUtils.formatDate(DateTimeUtils.YYYY_MM_DD,new Date()));
        po.setIp(IpLocalUtil.getHostIp());
       
        if(lockJobDao.insert(po)>0) {
            LOGGER.info("ScoreCalculation start");
            Date end = DateTimeUtils.getDateWithoutHms(new Date());
            Date start = DateTimeUtils.getDateWithoutHms(DateTimeUtils.getYesterday());
            userDao.updateLevelPaid(start, end);
        }
    }
}

