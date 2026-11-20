-- ============================================================================
-- H2 测试专用 schema：与 db/game/V001__core.sql 的表集合等价（仅测试用，不是 V001 的替代品）。
-- 目标：H2 2.2 MODE=MySQL（见 GamePersistenceH2Test），列名/类型/键必须与 V001 保持一致，
-- 否则 mapper 里按列序位置映射的 record 会在测试里失去意义。
-- 与 V001 的差异（均为 H2 语法限制，已验证 2.2.224）：
--   * DROP TABLE IF EXISTS 前置：每个测试方法重建干净表，互不串数据。
--   * ENGINE/CHARSET 子句照抄——H2 MySQL 模式直接忽略它们，保留是为了和 V001 逐字对齐。
--   * 业务键列的 CHARACTER SET utf8mb4 COLLATE utf8mb4_bin 照抄——H2 MySQL 模式接受该子句，
--     但 H2 按列类型而非 collation 比较，大小写敏感语义只在真库验证（audit/迁移时人工盯）。
-- 生产库永远执行真正的 V001，这里只是让 mapper 的 SQL 能在 CI 里跑起来。
-- ============================================================================

DROP TABLE IF EXISTS game_shot;
DROP TABLE IF EXISTS game_coin_ledger;
DROP TABLE IF EXISTS game_match_player;
DROP TABLE IF EXISTS game_match;
DROP TABLE IF EXISTS game_wallet;
DROP TABLE IF EXISTS game_progress;
DROP TABLE IF EXISTS game_season;
DROP TABLE IF EXISTS game_profile;
DROP TABLE IF EXISTS game_schema_version;

CREATE TABLE game_schema_version (
  version_no INT NOT NULL PRIMARY KEY,
  description VARCHAR(200) NOT NULL,
  applied_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE game_profile (
  user_id BIGINT NOT NULL PRIMARY KEY,
  nickname VARCHAR(32) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  last_seen_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY ix_game_profile_seen (last_seen_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE game_progress (
  user_id BIGINT NOT NULL PRIMARY KEY,
  season_no INT NOT NULL,
  tier TINYINT NOT NULL DEFAULT 0,
  stars TINYINT NOT NULL DEFAULT 0,
  mmr INT NOT NULL DEFAULT 1200,
  loss_streak TINYINT NOT NULL DEFAULT 0,
  wins INT NOT NULL DEFAULT 0,
  losses INT NOT NULL DEFAULT 0,
  total_hits INT NOT NULL DEFAULT 0,
  best_tier TINYINT NOT NULL DEFAULT 0,
  best_stars TINYINT NOT NULL DEFAULT 0,
  streak INT NOT NULL DEFAULT 0,
  scoring_games INT NOT NULL DEFAULT 0,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY ix_game_progress_board (tier, stars, wins)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE game_wallet (
  user_id BIGINT NOT NULL PRIMARY KEY,
  coin_balance INT NOT NULL DEFAULT 0,
  day_key VARCHAR(10) NOT NULL,
  login_done TINYINT NOT NULL DEFAULT 0,
  game_grants INT NOT NULL DEFAULT 0,
  ticket_plays INT NOT NULL DEFAULT 0,
  ad_grants INT NOT NULL DEFAULT 0,
  net_gain INT NOT NULL DEFAULT 0,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE game_coin_ledger (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT NOT NULL,
  entry_key VARCHAR(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  reason VARCHAR(16) NOT NULL,
  delta INT NOT NULL,
  ref VARCHAR(64) DEFAULT NULL,
  at_ms BIGINT NOT NULL,
  capped TINYINT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_game_coin_ledger_entry (user_id, entry_key),
  KEY ix_game_coin_ledger_user (user_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE game_match (
  match_id VARCHAR(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  season_no INT NOT NULL,
  mode VARCHAR(12) NOT NULL,
  preset VARCHAR(12) NOT NULL,
  capacity TINYINT NOT NULL,
  ticket VARCHAR(12) NOT NULL DEFAULT 'free',
  board_size TINYINT NOT NULL,
  plane_count TINYINT NOT NULL,
  started_at_ms BIGINT NOT NULL,
  ended_at_ms BIGINT DEFAULT NULL,
  duration_ms INT DEFAULT NULL,
  finished TINYINT NOT NULL DEFAULT 0,
  close_reason VARCHAR(16) DEFAULT NULL,
  human_count TINYINT NOT NULL DEFAULT 0,
  KEY ix_game_match_season (season_no, started_at_ms)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE game_match_player (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  match_id VARCHAR(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  seat TINYINT NOT NULL,
  user_id BIGINT DEFAULT NULL,
  bot TINYINT NOT NULL DEFAULT 0,
  final_rank TINYINT DEFAULT NULL,
  eliminated_round INT DEFAULT NULL,
  hits INT NOT NULL DEFAULT 0,
  win TINYINT NOT NULL DEFAULT 0,
  delta_star TINYINT NOT NULL DEFAULT 0,
  mmr_before INT DEFAULT NULL,
  mmr_after INT DEFAULT NULL,
  scoring TINYINT NOT NULL DEFAULT 0,
  UNIQUE KEY uk_game_match_player_seat (match_id, seat),
  KEY ix_game_match_player_user (user_id, match_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE game_season (
  season_no INT NOT NULL PRIMARY KEY,
  started_at_ms BIGINT NOT NULL,
  ends_at_ms BIGINT NOT NULL,
  status VARCHAR(12) NOT NULL DEFAULT 'ACTIVE',
  granted_at DATETIME DEFAULT NULL,
  reset_at DATETIME DEFAULT NULL,
  note VARCHAR(200) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- V002 的表一并建好：mapper 位置映射约定对 shot 表同样适用，测试环境保持全表在位。
CREATE TABLE game_shot (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  match_id VARCHAR(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  seq INT NOT NULL,
  by_user BIGINT DEFAULT NULL,
  target_user BIGINT DEFAULT NULL,
  row_no TINYINT NOT NULL,
  col_no TINYINT NOT NULL,
  result VARCHAR(8) NOT NULL,
  plane_id VARCHAR(24) DEFAULT NULL,
  at_ms BIGINT NOT NULL,
  UNIQUE KEY uk_game_shot_seq (match_id, seq),
  KEY ix_game_shot_user (by_user, match_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
