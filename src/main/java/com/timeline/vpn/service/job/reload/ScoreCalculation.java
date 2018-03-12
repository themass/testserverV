package com.timeline.vpn.service.job.reload;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import com.timeline.vpn.dao.db.UserDao;
import com.timeline.vpn.service.job.ReloadJob;

/**
 * @author gqli
 * @date 2017年6月2日 下午9:35:47
 * @version V1.0
 */
@Component
public class ScoreCalculation extends ReloadJob{
    private static final Logger LOGGER = LoggerFactory.getLogger(ScoreCalculation.class);
    @Autowired
    private UserDao userDao;

    @Override
    @Transactional
    public void reload() {
        userDao.minusScore();
        userDao.initUserVip();
        userDao.initUserVip1();
        userDao.initUserVip2();
    }
}

