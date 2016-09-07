package com.timeline.vpn.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
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
    @Autowired
    private RedisTemplate<String, String> jedisTemplate;

    public String getToken(String name) {
        return String.format(TOKEN_ITEM_KEY, name);
    }

    public UserPo getUser(String token) {
        if (!StringUtils.isEmpty(token))
            return JsonUtil.readValue(jedisTemplate.opsForValue().get(token), UserPo.class);
        return null;
    }

    @Override
    public String putUser(UserPo user) {
        String token = String.format(TOKEN_ITEM_KEY, AuthUtil.nameToToken(user.getName()));
        jedisTemplate.opsForValue().set(token, JsonUtil.writeValueAsString(user));
        return token;
    }

    @Override
    public void del(String token) {
        if (!StringUtils.isEmpty(token))
            jedisTemplate.delete(token);
    }

}

