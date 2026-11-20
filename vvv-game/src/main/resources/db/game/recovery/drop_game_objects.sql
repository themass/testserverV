-- ============================================================================
-- drop_game_objects.sql —— 回退逃生舱：删掉 V001/V002 建的所有 game_* 表
--
-- ⚠ 这不是日常脚本。执行 = 删库级操作，会连流水（合规留痕）、对局审计、钱包一起删光，
--   玩家数据不可恢复。执行前必须：
--     1. 取得用户（数据 Owner）的明确批准，留档；
--     2. 先做全量备份并验证备份可恢复（mysqldump --single-transaction）；
--     3. 确认当前库里只有演练数据，或数据已按要求导出。
--
-- 顺序说明：本套表没有外键（5.6 下有意不用），顺序不构成硬约束；
-- 这里仍按"先子（明细/流水）后父（身份/版本）"显式排列，
-- 万一将来有人补了外键，这个顺序天然是 FK-safe 的。
-- game_schema_version 最后删，这样半途失败时还能看出库处于哪个版本。
-- ============================================================================

DROP TABLE IF EXISTS game_shot;          -- V002 明细，最叶子
DROP TABLE IF EXISTS game_coin_ledger;   -- 流水（留痕）
DROP TABLE IF EXISTS game_match_player;  -- 座位明细
DROP TABLE IF EXISTS game_match;         -- 对局总账
DROP TABLE IF EXISTS game_wallet;        -- 钱包
DROP TABLE IF EXISTS game_progress;      -- 战绩聚合
DROP TABLE IF EXISTS game_season;        -- 赛季
DROP TABLE IF EXISTS game_profile;       -- 玩家身份
DROP TABLE IF EXISTS game_schema_version; -- 版本表最后删
