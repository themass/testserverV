package com.timeline.vpn.util.cache;


/**
 * 对接口返回值做缓存
 */
public interface ValueCache {


    /**
     * 获取值
     *
     * @param key
     * @param
     * @param
     * @return
     */
    Object getValue(String key, Long expire, Long cacheSize);

    /**
     * 设置值
     *
     * @param key
     * @param value
     * @param expire
     */
    void putValue(String key, Object value, Long expire, Long cacheSize);


    void clear(String key, Long expire, Long cacheSize);



}
