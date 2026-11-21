-- ============================================================================
-- V002__shots.sql —— game_shot：逐发炮弹，回放与反作弊（可选先不上）
-- 状态：未执行。执行方式见 docs/game/migration.md；必须在 V001 之后执行。
-- 目标库：同 V001（本机 bootstrap-*.yml 的 datasource.url，连接串不入库），MySQL 5.6；执行前先备份。
-- 生命周期：90 天后删除（见 docs/game/data-model.md 表清单），不进备份长期目标。
-- ============================================================================

CREATE TABLE game_shot (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  match_id VARCHAR(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  seq INT NOT NULL,                                     -- 全局发炮顺序（桌子内单调）
  by_user BIGINT DEFAULT NULL,                          -- 电脑为 NULL
  target_user BIGINT DEFAULT NULL,
  row_no TINYINT NOT NULL,
  col_no TINYINT NOT NULL,
  result VARCHAR(8) NOT NULL,                           -- miss/body/head
  plane_id VARCHAR(24) DEFAULT NULL,                    -- 命中时哪架
  at_ms BIGINT NOT NULL,
  UNIQUE KEY uk_game_shot_seq (match_id, seq),
  KEY ix_game_shot_user (by_user, match_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO game_schema_version (version_no, description)
  VALUES (2, 'game shots: replay & anti-cheat');
