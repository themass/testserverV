package com.timeline.vpn.service.listener;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * @author gqli
 * @date 2017年4月12日 下午2:59:33
 * @version V1.0
 */
@Component
public class IpLocalDelegateListener implements MessageContentsDelegate{
    private static final Logger LOGGER = LoggerFactory.getLogger(IpLocalDelegateListener.class);
    @Override
    public void handleMessage(Object text) {
        LOGGER.info(text.toString());
    }
}

