-- V009: Poetry Studio 治理表。MySQL 5.6.40 兼容；刻意没有外键、JSON、CHECK、生成列。
-- 只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`；DDL 在 MySQL 不可回滚。
-- 一条一条地执行，每条之后看 `SHOW WARNINGS`。不要一次性 `source` 整个文件。
-- 前置：V007、V008 已执行（本文件给 poetry_agent_task / poetry_agent_proposal 加索引）。
--
-- ===== 部署顺序（重要） =====
--   1) 备份（mysqldump 到文件并确认非空；不要用 CREATE TABLE ... AS SELECT 当备份，它不保留主键与索引）。
--   2) 用"上一版"的 audit_integrity_checks.sql（不含 C10）跑基线，所有 bad_rows 必须为 0。
--   3) 执行本文件。
--   4) 再部署带"逐项评审"和 C10 审计的 vvv-poetry。
--   审计 SQL 里的 C10 引用了本文件建的两张表。AuditRunner 把整个审计文件当一条语句执行：表不存在时审计跑不起来，
--   所有发布都会被挡（"audit could not run"）。所以本文件必须先于带 C10 的 jar。
--   PoetryAgentService.apply 也会读 poetry_agent_proposal_item；表不存在时 apply 会失败（有意：不静默按旧行为执行）。
--
-- ===== 首次执行前的只读检查（每项都应满足） =====
--   SELECT VERSION();                                                    -- 5.6.40
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;     -- 1..8 都在
--   SHOW TABLES LIKE 'poetry_agent_proposal_item';                        -- 必须为空
--   SHOW TABLES LIKE 'poetry_studio_check_log';                           -- 必须为空
--   SHOW INDEX FROM poetry_agent_task WHERE Key_name='ix_poetry_agent_task_status_created';      -- 必须为空
--   SHOW INDEX FROM poetry_agent_proposal WHERE Key_name='ix_poetry_agent_proposal_created';    -- 必须为空
--   为什么表必须为空：CREATE TABLE IF NOT EXISTS 遇到同名旧表只给 warning（1050）然后继续，你得到的是一张结构不明的表。
--   下面每张表后面的 SELECT ... LIMIT 0 会在列缺失时报 1054，能挡住一部分这种情况，
--   但挡不住类型不同或缺主键，所以执行后仍要做文件末尾的 SHOW CREATE TABLE 核对。
--
-- ===== 中途失败怎么续 =====
--   语句 1、2（建表）：幂等，可以直接重新执行。
--   语句 3、4（建索引）：MySQL 5.6 没有 CREATE INDEX IF NOT EXISTS。报 1061（索引已存在）= 这一条上次已完成，
--     跳过它，继续下一条。报 1072 或 1146 = V007/V008 没执行，停下，先补齐。
--   语句 5（账本）：幂等（NOT EXISTS），可以任意次重新执行。
--   不要运行 recovery/V009_rollback.sql 来"从中间状态恢复"；需要退回时按该文件的说明逐步处理。
--
-- ===== 执行后的核对 =====
--   SHOW CREATE TABLE poetry_agent_proposal_item;     -- 主键 (proposal_id, item_index)；proposal_id 为 utf8mb4_bin
--   SHOW CREATE TABLE poetry_studio_check_log;        -- 三个 ix_poetry_studio_check_log_* 索引；source_id/claim_id/proposal_id 为 utf8mb4_bin
--   SHOW INDEX FROM poetry_agent_task;                -- 出现 ix_poetry_agent_task_status_created，旧索引一个不少
--   SHOW INDEX FROM poetry_agent_proposal;            -- 出现 ix_poetry_agent_proposal_created，旧索引一个不少
--   SELECT version_no, description FROM poetry_schema_version WHERE version_no=9;   -- 恰好一行
--   然后用新版 audit_integrity_checks.sql（含 C10，共 156 项）再跑一遍：所有 bad_rows 仍为 0。
--
-- 回滚：recovery/V009_rollback.sql（先回滚应用代码，再执行该 SQL；它会保留审计轨迹而不是删除）。
--
-- 1. 逐项评审记录（D7）：每个 (proposal_id, item_index) 一行，item_index 为 proposal.changes 的 0 起始下标。
--    apply 的语义：提案下完全没有本表记录 -> 旧行为（全部可执行项都执行）；有任一记录 -> 只执行 decision='APPROVE' 的可执行项。
--    主键 64*4+4 = 260 字节，低于 767。
CREATE TABLE IF NOT EXISTS poetry_agent_proposal_item (
  proposal_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  item_index INT NOT NULL,
  decision VARCHAR(16) NOT NULL,
  reviewer VARCHAR(100) NOT NULL,
  comment TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME,
  PRIMARY KEY (proposal_id, item_index)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- 结构断言：缺任何一列都会报 1054。
SELECT proposal_id, item_index, decision, reviewer, comment, created_at, updated_at FROM poetry_agent_proposal_item LIMIT 0;

-- 2. Studio 人工写入审计（只追加，永不 UPDATE/DELETE）。
--    与契约的偏差：source_id 允许 NULL，因为逐项评审(ITEM_DECISIONS)没有来源。
--    索引字节：source_id/proposal_id 64*4+8 = 264；reviewer 100*4+8 = 408，均低于 767。
--    这是"谁在何时把某条引用的 locator 改成了什么"的唯一记录（locator 的写入不进 poetry_review_log）。
CREATE TABLE IF NOT EXISTS poetry_studio_check_log (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  action VARCHAR(32) NOT NULL,
  source_id VARCHAR(64) COLLATE utf8mb4_bin NULL,
  claim_id VARCHAR(64) COLLATE utf8mb4_bin NULL,
  proposal_id VARCHAR(64) COLLATE utf8mb4_bin NULL,
  locator VARCHAR(300) NULL,
  evidence_excerpt TEXT NULL,
  decision VARCHAR(16) NULL,
  reviewer VARCHAR(100) NOT NULL,
  reviewer_role VARCHAR(32) NOT NULL,
  note TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY ix_poetry_studio_check_log_source (source_id, id),
  KEY ix_poetry_studio_check_log_proposal (proposal_id, id),
  KEY ix_poetry_studio_check_log_reviewer (reviewer, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
SELECT id, action, source_id, claim_id, proposal_id, locator, evidence_excerpt, decision, reviewer, reviewer_role, note, created_at FROM poetry_studio_check_log LIMIT 0;

-- 3. 列表查询索引（新增，不改旧索引）。重复执行报 1061（重名）属预期：这一条已完成，继续下一条。
CREATE INDEX ix_poetry_agent_task_status_created ON poetry_agent_task (status, created_at);
CREATE INDEX ix_poetry_agent_proposal_created ON poetry_agent_proposal (created_at);

-- 4. 版本账本（幂等：已记过账则不再插入。写法同 V007 对 V006 的补记）。
INSERT INTO poetry_schema_version (version_no, description)
SELECT 9, 'Studio governance: per-item proposal review, human check log, list indexes; no foreign keys' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no=9);
