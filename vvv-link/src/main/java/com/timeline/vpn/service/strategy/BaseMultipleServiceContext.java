package com.timeline.vpn.service.strategy;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.ArrayList;
import java.util.List;

/**
 * @Description: 
 * @author gqli
 * @date 2017年5月23日 上午11:40:49
 * @version V1.0
 */
public abstract class BaseMultipleServiceContext<O,T extends BaseSupportHandle<O>> {
    private static final Logger LOGGER = LoggerFactory.getLogger(BaseMultipleServiceContext.class);

    @Autowired(required=false)
    private List<T> handles = new ArrayList<>();
    public List<T> getService(O support) {
        List<T> list = new ArrayList<>();
        for (T handle : handles) {
            if(handle.support(support)){
                list.add(handle);
            }
        }
//        LOGGER.debug("获取handle 列表：{}"+list);
        return list;
    }
}

