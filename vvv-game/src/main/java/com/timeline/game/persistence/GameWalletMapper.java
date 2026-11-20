package com.timeline.game.persistence;

import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

/**
 * 只碰 game_wallet 一张表。注解 SQL（无 XML、无 @Table）；
 * 结果按 record 构造器参数顺序位置映射，SELECT 列序 = record 组件序。
 *
 * 两条并发防线都在这里（外层还有 game:lock:user:{userId} 应用锁兜底）：
 * 日计数用 day_key 做 CAS（失败=跨日或赛跑，调用方带新 day_key 重算），
 * 余额用"加完不许为负"的条件更新（失败=余额不足），全程不加行锁外的读改写。
 */
public interface GameWalletMapper {
    record WalletRow(long userId, int coinBalance, String dayKey, int loginDone,
                     int gameGrants, int ticketPlays, int adGrants, int netGain) {}

    /** ProfileView 三行单键读之一。 */
    @Select("SELECT user_id, coin_balance, day_key, login_done, game_grants, ticket_plays, "
        + "ad_grants, net_gain FROM game_wallet WHERE user_id=#{userId}")
    WalletRow wallet(@Param("userId") long userId);

    /** 首见建档：余额 0、计数全 0 由 DDL 默认值给出，day_key 由调用方按服务端本地日传入。 */
    @Insert("INSERT INTO game_wallet (user_id, day_key) VALUES (#{userId}, #{dayKey})")
    int insertInitial(@Param("userId") long userId, @Param("dayKey") String dayKey);

    /**
     * 覆盖当日计数器：WHERE day_key=旧值 即 CAS，返回 0 = 日切了或被并发改过 →
     * 调用方读回新行、按新 day_key 重算再来一遍（不重试则丢计数）。
     */
    @Update("UPDATE game_wallet SET day_key=#{dayKey}, login_done=#{loginDone}, "
        + "game_grants=#{gameGrants}, ticket_plays=#{ticketPlays}, ad_grants=#{adGrants}, "
        + "net_gain=#{netGain} WHERE user_id=#{userId} AND day_key=#{oldDayKey}")
    int casUpdateDay(@Param("userId") long userId, @Param("dayKey") String dayKey,
                     @Param("loginDone") int loginDone, @Param("gameGrants") int gameGrants,
                     @Param("ticketPlays") int ticketPlays, @Param("adGrants") int adGrants,
                     @Param("netGain") int netGain, @Param("oldDayKey") String oldDayKey);

    /** 余额变动（与 ledger 写入同事务）：返回 0 = 余额不足以支出，调用方拒绝并原样返回。 */
    @Update("UPDATE game_wallet SET coin_balance=coin_balance+#{delta} "
        + "WHERE user_id=#{userId} AND coin_balance+#{delta}>=0")
    int addBalance(@Param("userId") long userId, @Param("delta") int delta);
}
