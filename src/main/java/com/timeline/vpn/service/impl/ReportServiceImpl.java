package com.timeline.vpn.service.impl;

import java.io.File;
import java.util.Date;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.multipart.MultipartFile;

import com.alibaba.druid.filter.AutoLoad;
import com.timeline.vpn.ConstantProfile;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.service.ReportService;
import com.timeline.vpn.util.DateTimeUtils;

/**
 * @author gqli
 * @date 2016年12月28日 下午8:59:42
 * @version V1.0
 */
@AutoLoad
public class ReportServiceImpl implements ReportService{
    private static final Logger LOGGER = LoggerFactory.getLogger(ReportServiceImpl.class);
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
                String name = file.getOriginalFilename()+"_"+baseQuery.getAppInfo().getDevId()+"_"+DateTimeUtils.formatDate(DateTimeUtils.TIMEFORMAT,new Date());
                file.transferTo(new File(datePath,name));
            } catch (Exception e) {
                LOGGER.error("",e);
            }
        }
    }

}

