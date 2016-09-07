package com.timeline.vpn.dao.db;

import org.apache.ibatis.annotations.Param;

import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.UserPo;

/**
 * @author gqli
 * @date 2016年8月9日 上午11:22:16
 * @version V1.0
 */
public interface UserDao extends BaseDBDao<UserPo> {
    public UserPo get(@Param(value = "name") String name, @Param(value = "pwd") String pwd);

    public UserPo exist(String name);

    public void score(@Param(value = "score") long score, @Param(value = "name") String name);
}

