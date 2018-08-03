package com.timeline.vpn.service;

import java.util.List;

import org.springframework.web.multipart.MultipartFile;

import com.timeline.vpn.model.form.ConnLogForm;
import com.timeline.vpn.model.param.BaseQuery;

/**
 * @author gqli
 * @date 2016年12月28日 下午8:58:48
 * @version V1.0
 */
public interface ReportService {
    public void reportBug(BaseQuery baseQuery,List<MultipartFile> fileList);
    public void connlog(BaseQuery baseQuery,ConnLogForm logs);
    public void collect(BaseQuery baseQuery, Integer count, String localhost,String ip);
    public void pingCheck(BaseQuery baseQuery, Integer type, String ip);
}

