-- ============================================================================
-- V001__core.sql —— game_* 核心表（profile/progress/wallet/ledger/match/match_player/season）
-- 状态：2026-11-22 已在线上库执行（真库实测 MySQL 8.0.46）。记录见 docs/game/migration.md。
-- 目标库：本机 bootstrap-*.yml 的 spring.datasource.url 所指库（连接串不入库），
-- MySQL 5.6（local 与 prod 指向同一台线上库）。
-- 执行前必须先备份（无建库权限，只能靠前缀隔离 + 备份 + 可回退脚本兜底）。
-- 5.6 约束：不用 JSON / CHECK / 生成列 / 外键 / 窗口函数；业务键列 utf8mb4_bin 保大小写敏感。
-- 幂等与一致性约定（entry_key 词表、finished=0 抢占结算）见 docs/game/data-model.md。
-- ============================================================================

CREATE TABLE game_schema_version (
  version_no INT NOT NULL PRIMARY KEY,
  description VARCHAR(200) NOT NULL,
  applied_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE game_profile (
  user_id BIGINT NOT NULL PRIMARY KEY,                 -- = vpn.user.id，游戏账号唯一派生来源
  nickname VARCHAR(32) NOT NULL,                        -- 游戏内昵称，可改，允许与他人重名
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  last_seen_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY ix_game_profile_seen (last_seen_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE game_progress (
  user_id BIGINT NOT NULL PRIMARY KEY,
  season_no INT NOT NULL,                               -- 当前行属于哪个赛季
  tier TINYINT NOT NULL DEFAULT 0,                      -- 0..7，词表见 rank.md：列兵…元帅
  stars TINYINT NOT NULL DEFAULT 0,
  mmr INT NOT NULL DEFAULT 1200,                        -- 隐藏分，永不下发客户端
  loss_streak TINYINT NOT NULL DEFAULT 0,               -- 连败保星计数
  wins INT NOT NULL DEFAULT 0,
  losses INT NOT NULL DEFAULT 0,
  total_hits INT NOT NULL DEFAULT 0,
  best_tier TINYINT NOT NULL DEFAULT 0,                 -- 历史最高（当时的显示值）
  best_stars TINYINT NOT NULL DEFAULT 0,
  streak INT NOT NULL DEFAULT 0,                        -- 当前连胜
  scoring_games INT NOT NULL DEFAULT 0,                 -- 计分局数（人机/练习局不增）
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY ix_game_progress_board (tier, stars, wins)        -- 排行榜：反向扫 + LIMIT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE game_wallet (
  user_id BIGINT NOT NULL PRIMARY KEY,
  coin_balance INT NOT NULL DEFAULT 0,                  -- 与 ledger 求和一致，由断言核查
  day_key VARCHAR(10) NOT NULL,                         -- '2026-11-21'，服务端本地日，跨日覆盖计数
  login_done TINYINT NOT NULL DEFAULT 0,
  game_grants INT NOT NULL DEFAULT 0,                   -- 当日"完成对局"发币次数（上限 20）
  ticket_plays INT NOT NULL DEFAULT 0,                  -- 当日付费门票局配额（上限 20）
  ad_grants INT NOT NULL DEFAULT 0,                     -- 当日广告奖励次数（上限 5）
  net_gain INT NOT NULL DEFAULT 0,                      -- 当日净增（封顶 500）
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE game_coin_ledger (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT NOT NULL,
  entry_key VARCHAR(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  reason VARCHAR(16) NOT NULL,                          -- login/game/ticket-fee/ticket-win/ticket-refund/ad/season-grant
  delta INT NOT NULL,                                   -- 收入正、支出负（截断后为实收额）
  ref VARCHAR(64) DEFAULT NULL,                         -- match_id / 广告位 / 赛季号
  at_ms BIGINT NOT NULL,
  capped TINYINT NOT NULL DEFAULT 0,                    -- 本笔被净增上限截断
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_game_coin_ledger_entry (user_id, entry_key),  -- 幂等：重复入账在此挡住
  KEY ix_game_coin_ledger_user (user_id, id)            -- 明细倒序取最近 100 条
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE game_match (
  match_id VARCHAR(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  season_no INT NOT NULL,
  mode VARCHAR(12) NOT NULL,                            -- duel / melee / practice
  preset VARCHAR(12) NOT NULL,                          -- beginner/standard/advanced/expert
  capacity TINYINT NOT NULL,                            -- 2/3/4
  ticket VARCHAR(12) NOT NULL DEFAULT 'free',           -- free/standard/advanced
  board_size TINYINT NOT NULL,
  plane_count TINYINT NOT NULL,
  started_at_ms BIGINT NOT NULL,
  ended_at_ms BIGINT DEFAULT NULL,
  duration_ms INT DEFAULT NULL,
  finished TINYINT NOT NULL DEFAULT 0,                  -- 1 = 正常结束并完成全部结算
  close_reason VARCHAR(16) DEFAULT NULL,                -- finished/abandoned/refunded/disbanded
  human_count TINYINT NOT NULL DEFAULT 0,               -- 0 局全人机（练习），决定是否计段
  KEY ix_game_match_season (season_no, started_at_ms)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE game_match_player (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  match_id VARCHAR(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  seat TINYINT NOT NULL,
  user_id BIGINT DEFAULT NULL,                          -- 电脑座位为 NULL
  bot TINYINT NOT NULL DEFAULT 0,
  final_rank TINYINT DEFAULT NULL,                      -- 1 起
  eliminated_round INT DEFAULT NULL,
  hits INT NOT NULL DEFAULT 0,
  win TINYINT NOT NULL DEFAULT 0,
  delta_star TINYINT NOT NULL DEFAULT 0,                -- +1/0/-1；scoring=0 时恒 0
  mmr_before INT DEFAULT NULL,
  mmr_after INT DEFAULT NULL,
  scoring TINYINT NOT NULL DEFAULT 0,                   -- 本局是否计段（人机参与即 0）
  UNIQUE KEY uk_game_match_player_seat (match_id, seat),
  KEY ix_game_match_player_user (user_id, match_id)     -- recent 列表 / 反作弊按人查
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE game_season (
  season_no INT NOT NULL PRIMARY KEY,
  started_at_ms BIGINT NOT NULL,
  ends_at_ms BIGINT NOT NULL,
  status VARCHAR(12) NOT NULL DEFAULT 'ACTIVE',         -- ACTIVE / CLOSED
  granted_at DATETIME DEFAULT NULL,                     -- 赛季段位奖励发放完成时刻
  reset_at DATETIME DEFAULT NULL,                       -- 全服段位重置完成时刻
  note VARCHAR(200) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO game_schema_version (version_no, description)
  VALUES (1, 'game core: profile/progress/wallet/ledger/match/match_player/season');
