package com.timeline.vpn.service.impl.handle.tts;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * @author gqli
 * @version V1.0
 * @date 2017年11月28日 下午6:32:52
 */
public abstract class BaseTtsHandleProxy extends BaseTtsHandle {
    protected static final Logger LOGGER =
            LoggerFactory.getLogger(BaseTtsHandleProxy.class);
    @Override
    public boolean isDefault() {
        return false;
    }

}

