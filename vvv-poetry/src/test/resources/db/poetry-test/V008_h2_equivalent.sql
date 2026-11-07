-- 仅用于 H2 测试：与 V008__agent_orchestration_state.sql 等价的列集合。
-- 原因：H2 2.2 的 MySQL 模式不接受 V008 的"单条 ALTER 带多个 ADD COLUMN ... AFTER"，也不接受
-- `COLLATE ... NOT NULL DEFAULT ''` 的子句顺序。所以这里拆成逐列语句、去掉 AFTER/COLLATE。
-- 生产库仍然执行真正的 V008；这里不是 V008 的替代品，列名/类型/默认值必须与 V008 保持一致。
ALTER TABLE poetry_agent_task ADD COLUMN title VARCHAR(200) DEFAULT '' NOT NULL;
ALTER TABLE poetry_agent_task ADD COLUMN instructions TEXT;
ALTER TABLE poetry_agent_task ADD COLUMN requested_profile VARCHAR(64) DEFAULT 'authoring' NOT NULL;
ALTER TABLE poetry_agent_task ADD COLUMN requested_role VARCHAR(32) DEFAULT 'CONTENT_EDITOR' NOT NULL;
ALTER TABLE poetry_agent_task ADD COLUMN active_run_id VARCHAR(64) NULL;
ALTER TABLE poetry_agent_run ADD COLUMN mandate_id VARCHAR(64) DEFAULT '' NOT NULL;
ALTER TABLE poetry_agent_run ADD COLUMN profile_name VARCHAR(64) DEFAULT 'authoring' NOT NULL;
ALTER TABLE poetry_agent_run ADD COLUMN runtime_thread_id VARCHAR(128) NULL;
ALTER TABLE poetry_agent_run ADD COLUMN runtime_run_id VARCHAR(128) NULL;
ALTER TABLE poetry_agent_run ADD COLUMN reason TEXT NULL;
INSERT INTO poetry_schema_version (version_no, description)
VALUES (8, 'Durable Poetry Studio task/run orchestration state; no foreign keys');
