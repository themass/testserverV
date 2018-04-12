package com.timeline.vpn.service;

import com.timeline.vpn.model.po.UserPo;

/**
 * @author gqli
 * @date 2015年12月14日 下午10:09:53
 * @version V1.0
 */
public interface CacheService {
    public String getToken(String name);

    public UserPo getUser(String token);

    public String putUser(UserPo user);
    public String updateUser(String token, UserPo user);

    public void del(String token);
    public void put(String key,String val, long timeout);
    public String get(String key);

    public Long lock(String lockKey);

    public void unlock(String lockKey);
}

