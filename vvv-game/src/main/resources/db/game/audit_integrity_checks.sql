-- ============================================================================
-- audit_integrity_checks.sql —— game_* 一致性核查清单（全部只读 SELECT，不写任何数据）
--
-- 怎么跑（手工）：
--   mysql -h mysql.sspacee.com -P 6666 -u <账号> -p vpn < audit_integrity_checks.sql
--   或用任意只读客户端整段粘贴执行。每一条都应返回 0 行（或差值 0）。
--   任何一条返回非 0，先别改数据：按 docs/game/data-model.md 的幂等约定回放结算
--   （finished=0 的行可安全重放），确认根因后再动，改数前后各留一份备份。
--
-- 约定（见 data-model.md）：coin_balance == SUM(ledger.delta)；
-- finished=1 必须已写 ended_at_ms；finished=0 超过 24h = 结算卡住需要回放。
-- ============================================================================

-- (a) 钱包余额 != 流水求和：应返回 0 行。
--     注意：余额与流水在两条语句里写，读到两者之间的瞬时窗口属正常，
--     复查同一 user_id 两次仍不一致才是真差异。
SELECT w.user_id,
       w.coin_balance,
       COALESCE(SUM(l.delta), 0) AS ledger_sum,
       w.coin_balance - COALESCE(SUM(l.delta), 0) AS diff
  FROM game_wallet w
  LEFT JOIN game_coin_ledger l ON l.user_id = w.user_id
 GROUP BY w.user_id, w.coin_balance
HAVING diff <> 0;

-- (a2) 有流水但没有钱包行：应返回 0 行（钱包缺失意味着后续所有 CAS 更新全部失效）。
SELECT DISTINCT l.user_id
  FROM game_coin_ledger l
  LEFT JOIN game_wallet w ON w.user_id = l.user_id
 WHERE w.user_id IS NULL;

-- (b) 已宣告完成（finished=1）却没写 ended_at_ms：应返回 0 行。
SELECT match_id, season_no, mode, started_at_ms, close_reason
  FROM game_match
 WHERE finished = 1
   AND ended_at_ms IS NULL;

-- (c) finished=0 且开局超过 24 小时：结算卡住的局，可按 finished=0 CAS 安全重放；
--     应返回 0 行。非 0 时把 match_id 交给回放任务，而不是手工 UPDATE。
SELECT match_id, season_no, mode, started_at_ms, human_count
  FROM game_match
 WHERE finished = 0
   AND started_at_ms < (UNIX_TIMESTAMP() - 24 * 3600) * 1000;

-- (d) 已结束的局，座位行数 != capacity：应返回 0 行。
--     缺座 = 结算只结了一部分人（发币/星/MMR 半途中断），按 finished=0 回放前先人工核对。
SELECT m.match_id, m.capacity, COUNT(p.id) AS seat_rows
  FROM game_match m
  LEFT JOIN game_match_player p ON p.match_id = m.match_id
 WHERE m.finished = 1
 GROUP BY m.match_id, m.capacity
HAVING seat_rows <> m.capacity;

-- (e) 参考项（非告警）：progress.season_no 落后于当前 ACTIVE 赛季的行数。
--     赛季重置是分批跑的（seasonResetBatch + LIMIT），跑批期间非 0 属正常；
--     重置完成后仍非 0 才说明漏行。期望值：重置完成后 = 0。
SELECT COUNT(*) AS stale_progress_rows
  FROM game_progress g
 CROSS JOIN (SELECT MAX(season_no) AS cur FROM game_season WHERE status = 'ACTIVE') s
 WHERE g.season_no <> s.cur;
