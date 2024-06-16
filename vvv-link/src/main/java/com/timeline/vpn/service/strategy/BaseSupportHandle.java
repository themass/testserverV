package com.timeline.vpn.service.strategy;

/**
 * @author gqli
 * @date 2017年5月22日 下午1:27:22
 * @version V1.0
 */
public interface BaseSupportHandle<T> {
    public boolean support(T t);
    public boolean isDefault();
}

