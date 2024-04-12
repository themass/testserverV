package com.timeline.vpn.service.strategy;

import java.util.List;
import java.util.Map;

import javax.annotation.PostConstruct;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;

import com.google.common.collect.Maps;
import com.timeline.vpn.exception.DataException;
import com.timeline.vpn.service.strategy.BaseServiceProxy.NameService;

/**
 * @author gqli
 * @date 2016年10月21日 下午1:51:42
 * @version V1.0
 */
public abstract class BaseServiceProxy<T extends NameService> {
    @Autowired
    protected List<T> serviceMap;
    protected Map<String, T> nameMap = Maps.newHashMap();
    private static final Logger LOGGER = LoggerFactory.getLogger(BaseServiceProxy.class);

    @PostConstruct
    public void init() {
        for (T f : serviceMap) {
            nameMap.put(f.getNameService(), f);
        }
    }

    public T getService(String name) {
        T server = nameMap.get(name);
        if (server == null) {
            if (getDefaultName() == null) {
                LOGGER.error(getClass().getSimpleName() + "->该服务还没上线：" + name);
                throw new DataException();
            }
            server = nameMap.get(getDefaultName());
        }
        return server;
    }

    /**
     * 
     * @Description:找不到相关服务，就使用默认服务，如果默认服务为null，抛出异常
     * @return
     */
    protected abstract String getDefaultName();

    public interface NameService {
        public String getNameService();
    }

}

