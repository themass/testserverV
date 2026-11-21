# game_* 数据模型

## 硬性前提（照抄 vvv-student / vvv-poetry 的既有教训）

- 目标库：`spring.datasource.url`（见本机 bootstrap-*.yml，连接串不入库）。**2026-11-22 真库实测 MySQL 8.0.46**
  （旧文档写 5.6.40 源自 TS 项目的过时情报）。`local` 与 `prod` 两个 profile 指向**同一台线上库**，
  账号无建库权限 → 只能靠 `game_` 前缀隔离 + 备份 + 可回退脚本。
- 写法仍按 5.6 子集（JSON 类型、CHECK、生成列、外键、窗口函数全部不用）：既是历史判断，也保前向兼容。
- 建表全部 `ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`；
  业务键（幂等键、roomCode、match_id）用 `utf8mb4_bin` 保持大小写敏感。
- 时间：审计列用 `DATETIME DEFAULT CURRENT_TIMESTAMP`（DB 时钟，UTC 部署时注意 server 时区）；
  业务毫秒戳用 `BIGINT`（客户端/游戏逻辑只看这个，避免时区歧义）。
- 索引命名 `ix_<表>_<列>` / `uk_<表>_<列>`。

## 表清单

| 表 | 作用 | 生命周期 |
|---|---|---|
| `game_schema_version` | 结构版本 | 永久 |
| `game_profile` | 玩家身份（昵称、首见/最近活跃） | 永久（可单用户删除） |
| `game_progress` | 段位/MMR/战绩聚合（显示壳 + 统计） | 永久 |
| `game_wallet` | 金币余额 + 当日计数器 | 永久（日计数按 day_key 覆盖） |
| `game_coin_ledger` | 金币流水，**唯一真相**，幂等键落库 | 永久（合规留痕，不删） |
| `game_match` | 一局一行的对局总账（审计） | 365 天后归档删除 |
| `game_match_player` | 每座位一行：名次/命中/星级变化/MMR 前后 | 随 game_match |
| `game_shot`（V002） | 逐发炮弹，回放与反作弊 | 90 天后删除 |
| `game_season` | 赛季边界与发奖/重置进度 | 永久 |

派生关系：客户端 `recent` 列表由 `game_match_player` + `game_match` 联查得到（**不另存冗余 recent 表**，
避免双写不一致）；`ProfileView` = profile + progress + wallet 三行单键读。

## DDL（V001__core.sql，2026-11-22 已在线上库执行）

```sql
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
  mode VARCHAR(12) NOT NULL,                            -- duel / melee（棋盘玩法，取自引擎；练习桌引擎同为 duel，桌类型不在本列）
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
```

V002__shots.sql（回放与审计，可选先不上）：

```sql
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
```

## 幂等与一致性约定（健壮性的落点）

| 场景 | 幂等键 / 手段 |
|---|---|
| 金币入账（登录礼/对局奖励/门票/退款/广告/赛季） | `game_coin_ledger.uk (user_id, entry_key)`；`entry_key` 词表见下。重复请求被唯一键挡 → 读回原结果，`applied=0` |
| 一局结算（多玩家各自发币 + 星 + MMR） | `game_match.match_id` = `<tableId>:<gamesPlayed>`；`finished=0` 的行可安全重放结算，置 1 的不可重放（结算前 `UPDATE ... SET finished=1 WHERE match_id=? AND finished=0` 抢占，影响行数 0 即已有人结过） |
| 门票退款 | `entry_key = 'ticket-refund:' + match_id`，与扣费天然配对，不受净增上限 |
| 跨进程并发（同一用户双开连接） | 写路径全走 `RedisLockServiceImpl` 锁 `game:lock:user:{userId}`（setIfAbsent + clientId 比较，见 vvv-common 既有实现） |
| 钱包 vs 流水 | 断言 `coin_balance == SUM(delta)`（`audit_integrity_checks.sql`，学 poetry 的核查清单，应全 0） |

`entry_key` 词表（与 TS `coins.ts` 的 reason 一一对应）：
`login:<day_key>`、`game:<match_id>`、`ticket-fee:<match_id>`、`ticket-win:<match_id>`、
`ticket-refund:<match_id>`、`ad:<day_key>:<序号>`、`season-grant:<season_no>`。

## 与 TS 实现的差异（有意为之）

| TS（内存 + JSON 文件） | Java |
|---|---|
| 账本只留最近 100 条，更早折进余额 | DB 全量留痕；展示层取最近 100 条 |
| `GameSummary` 冗余存档案 | 由 `game_match_player` 联查派生 |
| 每日计数器整个对象换新 | 同表原地覆盖（`WHERE day_key = ?`，更新失败即跨日 → 带新 day_key 重跑） |
| MMR/段位全在一个 profile 对象 | profile / progress / wallet 三行，单键读，边界清晰 |

## 删除一个玩家

`DELETE FROM game_* WHERE user_id = ?`（六表 + wallet + ledger；match_player 按 user_id 清座位行，match 保留匿名统计）。
这是隐私侧的既有要求（同 student 模块的单删契约），实现放 `GameForgetService`，仅管理端可触发。
