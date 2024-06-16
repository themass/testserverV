package com.timeline.vpn.service.job.reload;

import com.timeline.vpn.dao.db.RadacctDao;
import com.timeline.vpn.service.job.ReloadJob;
import com.timeline.vpn.util.DateTimeUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.Date;

/**
 * @author gqli
 * @date 2017年6月2日 下午9:35:47
 * @version V1.0
 */
@Component
public class DeleInvalidAcc extends ReloadJob{
    private static final Logger LOGGER = LoggerFactory.getLogger(DeleInvalidAcc.class);
    @Autowired
    private RadacctDao radacctDao;

    @Override
    public void reload() {
        Date time = DateTimeUtils.addHour(new Date(), -8);
        int count = radacctDao.deleteHistoryAcce(time);
        LOGGER.info("删除历史 acct数据："+count);
//        count = radacctDao.deleteHistoryAuth(time);
//        LOGGER.info("删除历史 auth数据："+count);
    }
}

