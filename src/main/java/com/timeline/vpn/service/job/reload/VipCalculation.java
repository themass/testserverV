package com.timeline.vpn.service.job.reload;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import com.timeline.vpn.dao.db.UserDao;
import com.timeline.vpn.service.CacheService;
import com.timeline.vpn.service.job.ReloadJob;

/**
 * @author gqli
 * @date 2017年6月2日 下午9:35:47
 * @version V1.0
 */
@Component
public class VipCalculation extends ReloadJob{
    private static final Logger LOGGER = LoggerFactory.getLogger(VipCalculation.class);
    @Autowired
    private UserDao userDao;
    @Autowired
    private CacheService cacheService;

    @Override
    @Transactional
    public void reload() {
        if(cacheService.lock("VipCalculation")>0) {
            LOGGER.info("VipCalculation start");
            userDao.initUserVip1();
            userDao.initUserVip2();
        }
    }
}

