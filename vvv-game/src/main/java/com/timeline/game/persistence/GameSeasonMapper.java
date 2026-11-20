package com.timeline.game.persistence;

import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import java.util.Date;

/**
 * 只碰 game_season 一张表（赛季边界 + 发奖/重置进度标记）。
 * 注解 SQL（无 XML、无 @Table）；结果按 record 构造器参数顺序位置映射。
 * granted_at/reset_at 是"哪一步跑完了"的断点标记：跑批中途挂了从这里续，不重发奖。
 */
public interface GameSeasonMapper {
    record SeasonRow(int seasonNo, long startedAtMs, long endsAtMs, String status,
                     Date grantedAt, Date resetAt) {}

    /** 幂等建赛季：重复 ensure 被主键挡下（INSERT IGNORE），边界值不改。 */
    @Insert("INSERT IGNORE INTO game_season (season_no, started_at_ms, ends_at_ms) "
        + "VALUES (#{seasonNo}, #{startedAtMs}, #{endsAtMs})")
    int ensureRow(@Param("seasonNo") int seasonNo, @Param("startedAtMs") long startedAtMs,
                  @Param("endsAtMs") long endsAtMs);

    @Select("SELECT season_no, started_at_ms, ends_at_ms, status, granted_at, reset_at "
        + "FROM game_season WHERE season_no=#{seasonNo}")
    SeasonRow season(@Param("seasonNo") int seasonNo);

    /** 发奖完成标记：DATETIME 用 DB 时钟（NOW），跑批续点只看"是不是 null"。 */
    @Update("UPDATE game_season SET granted_at=NOW() WHERE season_no=#{seasonNo}")
    int markGranted(@Param("seasonNo") int seasonNo);

    /** 全服重置完成标记。 */
    @Update("UPDATE game_season SET reset_at=NOW() WHERE season_no=#{seasonNo}")
    int markReset(@Param("seasonNo") int seasonNo);

    /** 收赛季：置 CLOSED；audit 里"当前赛季"取 status='ACTIVE' 的 MAX(season_no)，这一步决定其翻页。 */
    @Update("UPDATE game_season SET status='CLOSED' WHERE season_no=#{seasonNo}")
    int closeSeason(@Param("seasonNo") int seasonNo);
}
