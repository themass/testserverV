package com.timeline.game.persistence;

import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import java.util.List;

/**
 * 只碰 game_match_player 一张表（每座位一行：名次/命中/星级变化/MMR 前后）。
 * 注解 SQL（无 XML、无 @Table）；结果按 record 构造器参数顺序位置映射。
 * 可空列（电脑座位的 user_id、未结算的 final_rank 等）用包装类型，NULL → null。
 */
public interface GameMatchPlayerMapper {
    record SeatRow(int seat, Long userId, int bot, Integer finalRank, Integer eliminatedRound,
                   int hits, int win, int deltaStar, int scoring) {}

    @Insert("INSERT INTO game_match_player (match_id, seat, user_id, bot, final_rank, "
        + "eliminated_round, hits, win, delta_star, mmr_before, mmr_after, scoring) "
        + "VALUES (#{matchId}, #{seat}, #{userId}, #{bot}, #{finalRank}, #{eliminatedRound}, "
        + "#{hits}, #{win}, #{deltaStar}, #{mmrBefore}, #{mmrAfter}, #{scoring})")
    int insert(@Param("matchId") String matchId, @Param("seat") int seat,
               @Param("userId") Long userId, @Param("bot") int bot,
               @Param("finalRank") Integer finalRank, @Param("eliminatedRound") Integer eliminatedRound,
               @Param("hits") int hits, @Param("win") int win, @Param("deltaStar") int deltaStar,
               @Param("mmrBefore") Integer mmrBefore, @Param("mmrAfter") Integer mmrAfter,
               @Param("scoring") int scoring);

    /**
     * 结算回写座位行：开局（recordStart）先插"骨架行"（final_rank 等留 NULL，crash-sweep
     * 审计靠它认出未收尾的局），结算时原位覆盖成最终结果。
     * 定位键用 (match_id, user_id) 而非 seat：结算上下文只带 lastHumans 名单、没有座位号，
     * 而 uk_game_match_player_seat 保证一个真人一局只占一行；电脑行 user_id 为 NULL
     * 永不误中（SQL 三值逻辑：user_id = ? 对 NULL 恒不成立）。
     */
    @Update("UPDATE game_match_player SET final_rank=#{finalRank}, eliminated_round=#{eliminatedRound}, "
        + "hits=#{hits}, win=#{win}, delta_star=#{deltaStar}, mmr_before=#{mmrBefore}, "
        + "mmr_after=#{mmrAfter}, scoring=#{scoring} "
        + "WHERE match_id=#{matchId} AND user_id=#{userId}")
    int updateResult(@Param("matchId") String matchId, @Param("userId") long userId,
                     @Param("finalRank") Integer finalRank, @Param("eliminatedRound") Integer eliminatedRound,
                     @Param("hits") int hits, @Param("win") int win, @Param("deltaStar") int deltaStar,
                     @Param("mmrBefore") Integer mmrBefore, @Param("mmrAfter") Integer mmrAfter,
                     @Param("scoring") int scoring);

    /** 座位按序读回（回放与结算重放都要确定性顺序）；uk_game_match_player_seat 保证 seat 唯一。 */
    @Select("SELECT seat, user_id, bot, final_rank, eliminated_round, hits, win, delta_star, "
        + "scoring FROM game_match_player WHERE match_id=#{matchId} ORDER BY seat")
    List<SeatRow> seatsOfMatch(@Param("matchId") String matchId);
}
