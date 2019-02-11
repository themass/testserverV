package com.timeline.vpn.util.cache;


import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import com.google.common.cache.Cache;

public class MemCache implements ValueCache {

    String CACHE_NAME_TEMP = "%s_%s";

    private Map<String, Cache<String, Object>> caches =
            new ConcurrentHashMap<>();

    @Override
    public Object getValue(String key, Long expire, Long cacheSize) {
        return getCacheInstance(expire, cacheSize).getIfPresent(key);
    }


    @Override
    public void putValue(String key, Object value, Long expire, Long cacheSize) {
        getCacheInstance(expire, cacheSize).put(key, value);
    }

    @Override
    public void clear(String key, Long expire, Long cacheSize) {
        getCacheInstance(expire, cacheSize).invalidate(key);
    }

    private Cache<String, Object> getCacheInstance(Long expire, Long cacheSize) {
        String cacheName = String.format(CACHE_NAME_TEMP, expire,
                cacheSize);
        com.google.common.cache.Cache<String, Object> cacheInstance = caches.get(cacheName);
        if (cacheInstance == null) {
            cacheInstance = CacheUtil.build(expire, cacheSize);
            caches.put(cacheName, cacheInstance);
        }
        return cacheInstance;
    }
}
