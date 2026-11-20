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
     * 有意不写 season_no——赛季翻页只归 GameSeasonService（staleUserIds/seasonCross）管，
     * 结算路径永远不许跨赛季。
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
     * 跨季待翻页的行（TS resetSeasonAll 的等价扫描）：ORDER BY user_id 给确定性顺序，
     * 翻页后的行退出谓词，所以"一批打满 limit 就还有下一批"必然收敛。
     * 注意这里只选人不发币——奖励额取决于各自的旧段位，必须在 Java 侧逐行算
     * （TS crossSeason 先按上赛季段位发 (tier+1)×50 再降级，批量 SQL 做不到）。
     */
    @Select("SELECT user_id FROM game_progress WHERE season_no <> #{seasonNo} "
        + "ORDER BY user_id LIMIT #{limit}")
    List<Long> staleUserIds(@Param("seasonNo") int seasonNo, @Param("limit") int limit);

    /**
     * 单行跨季写：season_no 翻页 + 降级结果落库（tier/stars 由调用方用
     * {@code Rank.resetSeason} 算好传入；列兵行传回原值即"只翻页不动段"），
     * 连败清零、连胜与 mmr 与各项统计保留——与 TS resetSeason 逐字段对齐（rank.ts 100-104 行）。
     */
    @Update("UPDATE game_progress SET season_no=#{seasonNo}, tier=#{tier}, stars=#{stars}, "
        + "loss_streak=0 WHERE user_id=#{userId}")
    int seasonCross(@Param("userId") long userId, @Param("seasonNo") int seasonNo,
                    @Param("tier") int tier, @Param("stars") int stars);

    /** 排行榜：走 ix_game_progress_board 反向扫；并列按 user_id 定序保证分页稳定。 */
    @Select("SELECT user_id, tier, stars, wins FROM game_progress "
        + "WHERE season_no=#{seasonNo} "
        + "ORDER BY tier DESC, stars DESC, wins DESC, user_id ASC LIMIT #{limit}")
    List<BoardRow> board(@Param("seasonNo") int seasonNo, @Param("limit") int limit);
}
