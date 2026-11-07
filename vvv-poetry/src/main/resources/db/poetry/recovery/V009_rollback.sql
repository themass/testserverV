-- V009 回滚。只写文件，由用户在已备份的库上手工执行。一条一条执行，每条之后看 SHOW WARNINGS。
--
-- ===== 先做什么 =====
--   1) 先回滚/下线带"逐项评审"和 C10 审计的 vvv-poetry（PoetryAgentService.apply 会读 poetry_agent_proposal_item；
--      audit_integrity_checks.sql 里的 C10 引用下面要改名的两张表，留着新审计去跑旧库，所有发布会被挡）。
--   2) 再执行本文件。
--
-- ===== 每一步都独立；"对象不存在"表示该步骤以前做过或从未需要，跳过它，继续下一步 =====
--   步骤 1、2 报 1146（表不存在）= 跳过。步骤 3、4 报 1091（索引不存在）= 跳过。其他任何错误：停下。
--   这样不论 V009 做到哪一步中断过，都能把已建出来的东西逐项收拾干净。
--
-- ===== 为什么是改名而不是 DROP =====
--   poetry_studio_check_log 是"谁在何时把某条引用的 locator 改成了什么、谁核验了哪个来源"的唯一记录
--   （locator 的写入不进 poetry_review_log）。本回滚不撤销已写入 poetry_citation / poetry_source 的业务数据，
--   所以 DROP 之后，库里留下的 locator 与 VERIFIED 就没有任何出处了。改名保留数据、主键和索引，可逆。
--   不要用 CREATE TABLE ... AS SELECT 当备份：MySQL 5.6 里它不保留主键与索引。
--   下面的日期后缀请改成执行当天，避免与已有的改名表重名。确认不再需要后再手工 DROP 改名后的表。
-- 注意：本回滚不撤销 Studio 已写入的业务数据（citation 的 locator、source 的 VERIFIED）；
--   如需撤销，按 poetry_studio_check_log（改名后的表）与 poetry_review_log 人工处理。
--   reset_all_to_draft.sql 会把整个库的内容置回 DRAFT 并清空所有核验标记，不是"撤销 V009"，别当成它用。

-- 1. 人工核验/填 locator 的审计轨迹：改名保留。
ALTER TABLE poetry_studio_check_log RENAME TO poetry_studio_check_log_rolledback_20261107;

-- 2. 逐项评审记录：同样改名保留。
ALTER TABLE poetry_agent_proposal_item RENAME TO poetry_agent_proposal_item_rolledback_20261107;

-- 3、4. V009 加在旧表上的两个索引。它们在 V007 的表上，改名/删表都不会带走它们，必须单独删。
DROP INDEX ix_poetry_agent_proposal_created ON poetry_agent_proposal;
DROP INDEX ix_poetry_agent_task_status_created ON poetry_agent_task;

-- 5. 账本（幂等）。
DELETE FROM poetry_schema_version WHERE version_no = 9;
