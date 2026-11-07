package com.timeline.vpn.dao.db;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.Date;

/** 邀请码（表 vpn.user_invite 与 vpn.invite_code_history）。 */
@Mapper
public interface UserInviteDao {

    /** 查询用户当前的邀请码；没有则返回 null。 */
    String findCode(@Param("name") String name);

    /** 查询用户当前邀请码的发出时间；没有则返回 null。 */
    Date findCreatedAt(@Param("name") String name);

    /** 按邀请码查找仍在有效期内的邀请人用户名（created_at 不早于 since）；不存在返回 null。 */
    String findUserByCode(@Param("code") String code, @Param("since") Date since);

    /** 删除历史表里早于 cutoff 的该码记录（超过复用间隔，可以再次发出）。 */
    int deleteStaleHistory(@Param("code") String code, @Param("cutoff") Date cutoff);

    /** 记录一次发码；该码仍在复用间隔内时插入失败，返回 0。 */
    int insertHistory(@Param("code") String code, @Param("name") String name, @Param("issuedAt") Date issuedAt);

    /** 删除其他用户手里的同一个码（它已超过复用间隔，才会走到这里）。 */
    int deleteOtherOwner(@Param("code") String code, @Param("name") String name);

    /** 设置用户当前的邀请码。 */
    int upsert(@Param("name") String name, @Param("code") String code, @Param("createdAt") Date createdAt);
}
