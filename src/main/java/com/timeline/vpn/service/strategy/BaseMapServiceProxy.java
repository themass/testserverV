package com.timeline.vpn.service.strategy;

import java.util.Map;

import javax.annotation.PostConstruct;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;

import com.google.common.collect.Maps;
import com.timeline.vpn.Constant;
import com.timeline.vpn.VoBuilder;
import com.timeline.vpn.exception.DataException;
import com.timeline.vpn.model.param.DevApp;
import com.timeline.vpn.web.common.DevAppContext;

/**
 * @author gqli
 * @date 2016年10月21日 下午1:51:42
 * @version V1.0
 */
public abstract class BaseMapServiceProxy<T extends IAppAgent> {
    @Autowired
    protected Map<String, T> serviceMap;
    protected Map<String, T> channelMap = Maps.newHashMap();
    private static final Logger LOGGER = LoggerFactory.getLogger(BaseMapServiceProxy.class);

    @PostConstruct
    public void init() {
        VoBuilder.buildServiceProxy(serviceMap, channelMap);
    }
    public T getService() {
        DevApp app = DevAppContext.get();
        String ser = (Constant.VPNB.equals(app.getNetType())||Constant.VPNC.equals(app.getNetType())||Constant.VPND.equals(app.getNetType()))?Constant.VPNB:app.getChannel();
        T service = channelMap.get(ser);
        
        if(service==null)
            service = serviceMap.get(getDefaultName());
        if (service == null) {
            LOGGER.error(getClass().getSimpleName() + "->该服务还没上线：" + app);
            throw new DataException();
        }
        return service;
    }


    /**
     * 
     * @Description:找不到城市相关服务，就使用默认服务，如果默认服务为null，抛出异常
     * @return
     */
    protected abstract String getDefaultName();

}

