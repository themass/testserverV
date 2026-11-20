package com.timeline.game.persistence;

import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import java.util.List;

/**
 * 只碰 game_progress 一张表。注解 SQL（无 XML、无 @Table）；
 * 结果按 record 构造器参数顺序位置映射，SELECT 列序必须与 record 组件序完全一致。
 */
public interface GameProgressMapper {
    record ProgressRow(long userId, int seasonNo, int tier, int stars, int mmr, int lossStreak,
                       int wins, int losses, int totalHits, int bestTier, int bestStars,
                       int streak, int scoringGames) {}
    record BoardRow(long userId, int tier, int stars, int wins) {}

    /** ProfileView 三行单键读之一。 */
    @Select("SELECT user_id, season_no, tier, stars, mmr, loss_streak, wins, losses, "
        + "total_hits, best_tier, best_stars, streak, scoring_games "
        + "FROM game_progress WHERE user_id=#{userId}")
    ProgressRow progress(@Param("userId") long userId);

    /** 首见建档：其余列全走 DDL 默认值（mmr=1200，星/胜负/计数全 0）。 */
    @Insert("INSERT INTO game_progress (user_id, season_no) VALUES (#{userId}, #{seasonNo})")
    int insertInitial(@Param("userId") long userId, @Param("seasonNo") int seasonNo);

    /**
     * 结算落库：整行覆盖式写（调用方持用户锁，见 data-model.md 跨进程并发约定）。
     * 有意不写 season_no——赛季翻页只归 seasonResetBatch 管，结算路径永远不许跨赛季。
     */
    @Update("UPDATE game_progress SET tier=#{tier}, stars=#{stars}, "
        + "mmr=#{mmr}, loss_streak=#{lossStreak}, wins=#{wins}, losses=#{losses}, "
        + "total_hits=#{totalHits}, best_tier=#{bestTier}, best_stars=#{bestStars}, "
        + "streak=#{streak}, scoring_games=#{scoringGames} WHERE user_id=#{userId}")
    int updateProgress(@Param("userId") long userId,
                       @Param("tier") int tier, @Param("stars") int stars,
                       @Param("mmr") int mmr, @Param("lossStreak") int lossStreak,
                       @Param("wins") int wins, @Param("losses") int losses,
                       @Param("totalHits") int totalHits, @Param("bestTier") int bestTier,
                       @Param("bestStars") int bestStars, @Param("streak") int streak,
                       @Param("scoringGames") int scoringGames);

    /**
     * 赛季重置（分批）：段位/星清零、连败与连胜清零；mmr、wins/losses/total_hits、
     * scoring_games、best_tier/best_stars 是历史统计与匹配质量，保留不动。
     * MySQL 5.6 支持 UPDATE...LIMIT；循环补跑（直到返回 0）是调用方的事，别在这写循环。
     */
    @Update("UPDATE game_progress SET season_no=#{seasonNo}, tier=0, stars=0, "
        + "loss_streak=0, streak=0 WHERE season_no <> #{seasonNo} LIMIT #{limit}")
    int seasonResetBatch(@Param("seasonNo") int seasonNo, @Param("limit") int limit);

    /** 排行榜：走 ix_game_progress_board 反向扫；并列按 user_id 定序保证分页稳定。 */
    @Select("SELECT user_id, tier, stars, wins FROM game_progress "
        + "WHERE season_no=#{seasonNo} "
        + "ORDER BY tier DESC, stars DESC, wins DESC, user_id ASC LIMIT #{limit}")
    List<BoardRow> board(@Param("seasonNo") int seasonNo, @Param("limit") int limit);
}
