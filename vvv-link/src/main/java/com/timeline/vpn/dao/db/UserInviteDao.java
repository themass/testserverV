package com.timeline.vpn.dao.db;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.Date;

/** 邀请码（表 vpn.user_invite）。 */
@Mapper
public interface UserInviteDao {

    /** 查询用户已有的邀请码；没有则返回 null。 */
    String findCode(@Param("name") String name);

    /** 按邀请码查找邀请人用户名；不存在返回 null。 */
    String findUserByCode(@Param("code") String code);

    /** 写入邀请码；用户名或邀请码重复时忽略，返回 0。 */
    int insert(@Param("name") String name, @Param("code") String code, @Param("createdAt") Date createdAt);
}
