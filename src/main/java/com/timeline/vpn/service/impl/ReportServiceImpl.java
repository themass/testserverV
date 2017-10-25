package com.timeline.vpn.service.impl;

import java.io.File;
import java.util.Date;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import com.timeline.vpn.ConstantProfile;
import com.timeline.vpn.dao.db.CollectDao;
import com.timeline.vpn.metric.Measure;
import com.timeline.vpn.metric.Metrics;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.po.CollectPo;
import com.timeline.vpn.service.ReportService;
import com.timeline.vpn.util.DateTimeUtils;

/**
 * @author gqli
 * @date 2016年12月28日 下午8:59:42
 * @version V1.0
 */
@Component
public class ReportServiceImpl implements ReportService{
    private static final Logger LOGGER = LoggerFactory.getLogger(ReportServiceImpl.class);
    @Autowired
    private CollectDao collectDao;
    @Override
    public void reportBug(BaseQuery baseQuery, List<MultipartFile> fileList) {
        String dir = DateTimeUtils.formatDate(DateTimeUtils.DATEFORMAT,new Date());
        File datePath = new File(ConstantProfile.reportPath, dir);
        if(!datePath.exists()){
            datePath.mkdirs();
        }
        for(MultipartFile file:fileList){
            // 转存文件  
            try {
                String name = file.getOriginalFilename()+"_"+DateTimeUtils.formatDate(DateTimeUtils.TIMEFORMAT,new Date());
                file.transferTo(new File(datePath,name));
            } catch (Exception e) {
                LOGGER.error("",e);
            }
        }
    }
    @Override
    public void collect(BaseQuery baseQuery, Integer count, String localhost) {
        Metrics.count(Measure.vpn_connect.name(),count,localhost);
        CollectPo po = new CollectPo();
        po.setCount(count);
        po.setIp(baseQuery.getAppInfo().getUserIp());
        Date date = new Date();
        po.setDay(DateTimeUtils.formatDate(DateTimeUtils.DATEFORMAT,date));
        po.setHour(DateTimeUtils.formatDate("HH",date));
        po.setMinute(DateTimeUtils.formatDate("ss",date));
        collectDao.add(po);
        
    }

}

