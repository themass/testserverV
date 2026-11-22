package com.timeline.game.persistence;

import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import java.util.List;

/**
 * 只碰 game_match 一张表（一局一行的对局总账，审计用）。
 * 注解 SQL（无 XML、无 @Table）；结果按 record 构造器参数顺序位置映射。
 */
public interface GameMatchMapper {
    record MatchRow(String matchId, int seasonNo, String mode, String preset, int capacity,
                    String ticket, long startedAtMs, long endedAtMs, int finished,
                    String closeReason, int humanCount) {}
    /** recent 列表派生行：match 总账 + 该玩家自己的座位行联查（不另存冗余表）。 */
    record RecentRow(String matchId, String mode, String preset, int capacity, long startedAtMs,
                     long endedAtMs, int finalRank, int hits, int deltaStar, int win,
                     int scoring) {}

    @Insert("INSERT INTO game_match (match_id, season_no, mode, preset, capacity, ticket, "
        + "board_size, plane_count, started_at_ms, human_count) "
        + "VALUES (#{matchId}, #{seasonNo}, #{mode}, #{preset}, #{capacity}, #{ticket}, "
        + "#{boardSize}, #{planeCount}, #{startedAtMs}, #{humanCount})")
    int insert(@Param("matchId") String matchId, @Param("seasonNo") int seasonNo,
               @Param("mode") String mode, @Param("preset") String preset,
               @Param("capacity") int capacity, @Param("ticket") String ticket,
               @Param("boardSize") int boardSize, @Param("planeCount") int planeCount,
               @Param("startedAtMs") long startedAtMs, @Param("humanCount") int humanCount);

    /**
     * 结算抢占 CAS（data-model.md）：finished=0 → 1 抢到才许发币/结星，返回 0 = 已有人结过，
     * 直接读回既成结果。ended_at_ms 用 CAST(... AS DECIMAL(20,0))*1000 而非裸
     * UNIX_TIMESTAMP()*1000：MySQL 5.6 下 UNIX_TIMESTAMP() 是 BIGINT 不会溢出，但 H2 2.2
     * MySQL 模式把它当 INT，裸乘 1000 直接溢出——CAST 两边都精确且仍是 5.6 合法语法。
     */
    @Update("UPDATE game_match SET finished=1, "
        + "ended_at_ms=CAST(UNIX_TIMESTAMP() AS DECIMAL(20,0))*1000 "
        + "WHERE match_id=#{matchId} AND finished=0")
    int claimSettlement(@Param("matchId") String matchId);

    /** 非正常收尾（弃权/退款/解散）：只盖结束信息，结算抢占仍归 claimSettlement 管。 */
    @Update("UPDATE game_match SET close_reason=#{closeReason}, ended_at_ms=#{endedAtMs}, "
        + "duration_ms=#{durationMs} WHERE match_id=#{matchId}")
    int markClosed(@Param("matchId") String matchId, @Param("closeReason") String closeReason,
                   @Param("endedAtMs") long endedAtMs, @Param("durationMs") int durationMs);

    /** 按 id 读一行（回放/断言用）；finished 未结时为 0，调用方据此决定可否重放。 */
    @Select("SELECT match_id, season_no, mode, preset, capacity, ticket, started_at_ms, "
        + "COALESCE(ended_at_ms, 0), finished, COALESCE(close_reason, ''), human_count "
        + "FROM game_match WHERE match_id=#{matchId}")
    MatchRow match(@Param("matchId") String matchId);

    /**
     * 玩家的最近战绩：uk_game_match_player_seat 保证一局一人一行，联查不重复；
     * ix_game_match_player_user (user_id, match_id) 支撑按人取行。只回 finished=1 的局。
     */
    @Select("SELECT m.match_id, m.mode, m.preset, m.capacity, m.started_at_ms, m.ended_at_ms, "
        + "p.final_rank, p.hits, p.delta_star, p.win, p.scoring "
        + "FROM game_match m JOIN game_match_player p ON p.match_id=m.match_id "
        + "WHERE p.user_id=#{userId} AND m.finished=1 "
        + "ORDER BY m.started_at_ms DESC LIMIT #{limit}")
    List<RecentRow> recentByUser(@Param("userId") long userId, @Param("limit") int limit);
}
