package com.timeline.game.persistence;

import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import java.util.Date;
import java.util.List;

/**
 * 只碰 game_coin_ledger 一张表（金币唯一真相，合规留痕，不删不改）。
 * 注解 SQL（无 XML、无 @Table）；结果按 record 构造器参数顺序位置映射。
 */
public interface GameCoinLedgerMapper {
    record LedgerRow(long id, String entryKey, String reason, int delta, String ref,
                     long atMs, int capped, Date createdAt) {}

    /**
     * 幂等入账：重复 (user_id, entry_key) 被 uk_game_coin_ledger_entry 挡下，
     * INSERT IGNORE 返回 0 = 已入过账（调用方读回原结果、applied=0），不抛异常。
     */
    @Insert("INSERT IGNORE INTO game_coin_ledger "
        + "(user_id, entry_key, reason, delta, ref, at_ms, capped) "
        + "VALUES (#{userId}, #{entryKey}, #{reason}, #{delta}, #{ref}, #{atMs}, #{capped})")
    int insertIgnore(@Param("userId") long userId, @Param("entryKey") String entryKey,
                     @Param("reason") String reason, @Param("delta") int delta,
                     @Param("ref") String ref, @Param("atMs") long atMs,
                     @Param("capped") int capped);

    /** 明细倒序（走 ix_game_coin_ledger_user）：展示层取最近 100 条。 */
    @Select("SELECT id, entry_key, reason, delta, ref, at_ms, capped, created_at "
        + "FROM game_coin_ledger WHERE user_id=#{userId} ORDER BY id DESC LIMIT #{limit}")
    List<LedgerRow> ledger(@Param("userId") long userId, @Param("limit") int limit);

    /** 一致性核查用（wallet.balance == SUM(delta)）：无流水时返回 null，交由调用方判 0。 */
    @Select("SELECT SUM(delta) FROM game_coin_ledger WHERE user_id=#{userId}")
    Integer sumDelta(@Param("userId") long userId);
}
