package com.timeline.game.persistence;

import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

/**
 * 只碰 game_profile 一张表。按项目约定用注解 SQL（无 XML、无 @Table），
 * 列名 snake_case，结果按 record 构造器参数顺序位置映射（SELECT 列序 = 组件序）。
 */
public interface GameProfileMapper {
    record ProfileRow(long userId, String nickname) {}

    /** 首见即建档，再来即同步昵称；uk 就是主键 user_id，天然幂等。 */
    @Insert("INSERT INTO game_profile (user_id, nickname) VALUES (#{userId}, #{nickname}) "
        + "ON DUPLICATE KEY UPDATE nickname=VALUES(nickname)")
    int upsertProfile(@Param("userId") long userId, @Param("nickname") String nickname);

    /** 活跃时间戳；DATETIME 用 DB 时钟（NOW），避免应用机器时区把 last_seen 写花。 */
    @Update("UPDATE game_profile SET last_seen_at=NOW() WHERE user_id=#{userId}")
    int touchSeen(@Param("userId") long userId);

    @Select("SELECT user_id, nickname FROM game_profile WHERE user_id=#{userId}")
    ProfileRow profile(@Param("userId") long userId);

    /** 改名：返回 0 = 还没建过档（调用方应先 upsert）。 */
    @Update("UPDATE game_profile SET nickname=#{nickname} WHERE user_id=#{userId}")
    int renameProfile(@Param("userId") long userId, @Param("nickname") String nickname);
}
