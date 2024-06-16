package vpn.util.cache;

import com.google.common.cache.Cache;
import com.google.common.cache.CacheBuilder;

import java.util.concurrent.TimeUnit;


public class CacheUtil {


    public static Cache<String, Object> build(long expire, long maxSize) {
        return CacheBuilder.newBuilder().softValues().maximumSize(maxSize).expireAfterWrite(expire, TimeUnit.SECONDS).build();
    }
    public static String getVersion(String key) {
        return "verion_"+key;
    }
}
