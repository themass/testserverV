package com.timeline.vpn.service.job.reload;

import java.util.Date;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import com.timeline.vpn.dao.db.RadacctDao;
import com.timeline.vpn.service.job.ReloadJob;
import com.timeline.vpn.util.DateTimeUtils;

/**
 * @author gqli
 * @date 2017年6月2日 下午9:35:47
 * @version V1.0
 */
@Component
public class ClearData extends ReloadJob{
    private static final Logger LOGGER = LoggerFactory.getLogger(ClearData.class);
    @Autowired
    private RadacctDao radacctDao;

    @Override
    public void reload() {
        Date time = DateTimeUtils.addMonth(new Date(), -2);
        int count = radacctDao.deleteHistoryAcce(time);
        LOGGER.info("删除历史 acct数据："+count);
        count = radacctDao.deleteHistoryAuth(time);
        LOGGER.info("删除历史 auth数据："+count);
    }
}

