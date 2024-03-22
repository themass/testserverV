package com.timeline.vpn.service.impl;

import java.util.List;
import java.util.concurrent.TimeUnit;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataAccessException;
import org.springframework.data.redis.connection.RedisConnection;
import org.springframework.data.redis.core.RedisCallback;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import com.timeline.vpn.model.po.UserPo;
import com.timeline.vpn.service.CacheService;
import com.timeline.vpn.util.AuthUtil;
import com.timeline.vpn.util.JsonUtil;

/**
 * @author gqli
 * @date 2015年12月15日 上午10:46:41
 * @version V1.0
 */
@Service
public class CacheServiceImpl implements CacheService {
    private static final String TOKEN_ITEM_KEY = "token_%s";
    private static final String SCORE_ITEM_KEY = "score_%s";

    private static final long LOCK_TIMEOUT = 60 * 1000; //加锁超时时间 单位毫秒
    private static final long SCORE_TIMEOUT = 3600 * 1000; //加锁超时时间 单位毫秒
    public static final long USERCACH_TIMEOUT = 60*24; //加锁超时时间 单位毫秒

    @Autowired
    private RedisTemplate<String, String> jedisTemplate;
    private static final Logger LOGGER = LoggerFactory.getLogger(CacheServiceImpl.class);
    public String getToken(String name) {
        return String.format(TOKEN_ITEM_KEY, name);
    }

    public UserPo getUser(String token) {
        if (!StringUtils.isEmpty(token)) {
            String string = jedisTemplate.opsForValue().get(token);
            if(!StringUtils.isEmpty(string))
                return JsonUtil.readValue(string, UserPo.class);
        }
        return null;
    }

    @Override
    public String putUser(UserPo user) {
        String token = String.format(TOKEN_ITEM_KEY, AuthUtil.nameToToken(user.getName()));
        jedisTemplate.opsForValue().set(token, JsonUtil.writeValueAsString(user),USERCACH_TIMEOUT,TimeUnit.MINUTES);
        return token;
    }
    @Override
    public String updateUser(String token, UserPo user) {
        jedisTemplate.opsForValue().set(token, JsonUtil.writeValueAsString(user),USERCACH_TIMEOUT,TimeUnit.MINUTES);
        return token;
    }
    @Override
    public void del(String token) {
        if (!StringUtils.isEmpty(token))
            jedisTemplate.delete(token);
    }

    @Override
    public void put(String key, String val, long timeout) {
        jedisTemplate.opsForValue().set(key, val,timeout,TimeUnit.MINUTES);        
    }

    @Override
    public String get(String key) {
        return jedisTemplate.opsForValue().get(key);
    }
    @Override
    public Long lock(final String lockKey) {
//        LOGGER.info("开始执行加锁"+lockKey);
        Long lock_timeout = System.currentTimeMillis() + LOCK_TIMEOUT + 1; //锁时间
            if (jedisTemplate.execute(new RedisCallback<Boolean>() {
 
                @Override
                public Boolean doInRedis(RedisConnection connection) throws DataAccessException {
                    return connection.setNX(lockKey.getBytes(), "1".getBytes());
            }
        })) { //如果加锁成功
//            LOGGER.info("加锁成功++++++++"+lockKey);
            jedisTemplate.expire(lockKey, LOCK_TIMEOUT, TimeUnit.MILLISECONDS); //设置超时时间，释放内存
            return lock_timeout;
        }else {
//            LOGGER.info("加锁失败++++++++"+lockKey);
            return -1l;
        }
    }
 
    @Override
    public void unlock(String lockKey) {
        LOGGER.info("执行解锁==========");//正常直接删除 如果异常关闭判断加锁会判断过期时间
        jedisTemplate.delete(lockKey); //删除键
    } 

    @Override
    public int updateCount(UserPo user) {
        String count = jedisTemplate.opsForValue().get(String.format(SCORE_ITEM_KEY, user.getName()));
        if(StringUtils.isEmpty(count)) {
            jedisTemplate.opsForValue().set(String.format(SCORE_ITEM_KEY, user.getName()),"1",SCORE_TIMEOUT,TimeUnit.MILLISECONDS);
            return 0;
        }
        int countInt = Integer.parseInt(count);
        jedisTemplate.opsForValue().set(String.format(SCORE_ITEM_KEY, user.getName()),(countInt+1)+"",SCORE_TIMEOUT,TimeUnit.MILLISECONDS);

        return countInt;
    }
 

}

