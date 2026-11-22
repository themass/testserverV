package com.timeline.game.persistence;

import org.apache.ibatis.annotations.Delete;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

/**
 * 只碰 game_shot 一张表（V002：逐发炮弹，回放与反作弊，90 天生命周期）。
 * 注解 SQL（无 XML、无 @Table）；结果按 record 构造器参数顺序位置映射。
 * 可空列（电脑发炮的 by_user、未命中的 plane_id）用包装类型，NULL → null。
 */
public interface GameShotMapper {
    record ShotRow(Long byUser, Long targetUser, int rowNo, int colNo,
                   String result, String planeId, long atMs) {}

    /**
     * 落一发。INSERT IGNORE：唯一键 uk_game_shot_seq (match_id, seq) 挡下崩溃重放
     * 的半途重插（settle 抢占失败重发同批也无害），返回 0 = 已落过。
     */
    @Insert("INSERT IGNORE INTO game_shot (match_id, seq, by_user, target_user, row_no, col_no, "
        + "result, plane_id, at_ms) "
        + "VALUES (#{matchId}, #{seq}, #{byUser}, #{targetUser}, #{rowNo}, #{colNo}, "
        + "#{result}, #{planeId}, #{atMs})")
    int insert(@Param("matchId") String matchId, @Param("seq") int seq,
               @Param("byUser") Long byUser, @Param("targetUser") Long targetUser,
               @Param("rowNo") int rowNo, @Param("colNo") int colNo,
               @Param("result") String result, @Param("planeId") String planeId,
               @Param("atMs") long atMs);

    @Select("SELECT COUNT(*) FROM game_shot WHERE match_id = #{matchId}")
    long countByMatch(@Param("matchId") String matchId);

    /** 一局全部明细，按全局发炮序返回（回放与测试口径）。 */
    @Select("SELECT by_user, target_user, row_no, col_no, result, plane_id, at_ms FROM game_shot "
        + "WHERE match_id = #{matchId} ORDER BY seq")
    java.util.List<ShotRow> shotsOfMatch(@Param("matchId") String matchId);

    /** 生命周期清理（docs/game/data-model.md：90 天后删除）；LIMIT 分批由调用方循环。注解 SQL 非 XML，直接用 <。 */
    @Delete("DELETE FROM game_shot WHERE at_ms < #{beforeMs} LIMIT #{limit}")
    int purgeBefore(@Param("beforeMs") long beforeMs, @Param("limit") int limit);
}
