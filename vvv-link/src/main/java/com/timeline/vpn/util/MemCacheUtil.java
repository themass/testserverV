package com.timeline.vpn.util;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;

/**
*
 * @author gqli
 * @date 2015年7月30日 下午5:55:33
 * @version V1.0
 */
public class MemCacheUtil {
    private static final Logger LOGGER = LoggerFactory.getLogger(MemCacheUtil.class);

    private static Map<String, CacheEntry> cacheMap = new HashMap<String, CacheEntry>();

    /**
     * 
     * @Description:  添加内存缓存
     * @param key
     * @param val
     * @param timeOut  单位分钟
     */
    public static synchronized void set(String key, Object val, long timeOut) {
        timeOut = timeOut * 60 * 1000;
        CacheEntry entry = new CacheEntry(val, timeOut);
        cacheMap.put(key, entry);
    }

    @SuppressWarnings("unchecked")
    public static synchronized <T> T get(String key) {
        CacheEntry entry = cacheMap.get(key);
        if (entry != null) {
            long now = entry.expire + entry.timeStamp;
            if (now <= System.currentTimeMillis()) {
                cacheMap.remove(key);
                return null;
            }
            try {
                return (T) entry.cache;
            } catch (ClassCastException e) {
                LOGGER.error("", e);
                del(key);
            }
        }
        return null;
    }

    public static synchronized void del(String key) {
        cacheMap.remove(key);
    }

    public static synchronized int clear() {
        int size = cacheMap.size();
        cacheMap.clear();
        return size;
    }

    static class CacheEntry {
        public Long expire;
        public long timeStamp;
        public Object cache;

        public CacheEntry(Object cache, Long expire) {
            this.cache = cache;
            this.expire = expire;
            this.timeStamp = System.currentTimeMillis();
        }

    }
}

