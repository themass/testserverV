package com.timeline.vpn.dao.db;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.Date;
import java.util.List;

/** 激励视频观看券（表 vpn.user_reward_ticket）。 */
@Mapper
public interface RewardTicketDao {

    /** 写入一条记录；transaction_id 重复时忽略，返回 0。 */
    int insert(@Param("name") String name, @Param("tx") String tx, @Param("granted") int granted,
               @Param("createdAt") Date createdAt, @Param("expireAt") Date expireAt);

    int countGrantedSince(@Param("name") String name, @Param("since") Date since);

    Date lastGrantedAt(@Param("name") String name);

    int countAvailable(@Param("name") String name, @Param("now") Date now);

    /** 锁定最早的若干张可用观看券（SELECT ... FOR UPDATE，需在事务内调用）。 */
    List<Long> lockAvailable(@Param("name") String name, @Param("now") Date now, @Param("limit") int limit);

    int markUsed(@Param("ids") List<Long> ids);
}
