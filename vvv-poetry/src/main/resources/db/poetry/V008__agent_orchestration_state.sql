-- V008: durable BFF orchestration state. MySQL 5.6 compatible; deliberately no foreign keys.
-- V007 records Agent audit facts; this migration adds the request/run metadata needed to recover
-- Poetry Studio state after a BFF restart. Associations remain service-validated and audit-visible.

ALTER TABLE poetry_agent_task
  ADD COLUMN title VARCHAR(200) NOT NULL DEFAULT '' AFTER work_id,
  ADD COLUMN instructions TEXT NOT NULL AFTER title,
  ADD COLUMN requested_profile VARCHAR(64) NOT NULL DEFAULT 'authoring' AFTER instructions,
  ADD COLUMN requested_role VARCHAR(32) NOT NULL DEFAULT 'CONTENT_EDITOR' AFTER requested_by,
  ADD COLUMN active_run_id VARCHAR(64) COLLATE utf8mb4_bin NULL AFTER status,
  ADD KEY ix_poetry_agent_task_active_run (active_run_id);

ALTER TABLE poetry_agent_run
  ADD COLUMN mandate_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL DEFAULT '' AFTER task_id,
  ADD COLUMN profile_name VARCHAR(64) NOT NULL DEFAULT 'authoring' AFTER profile_fingerprint,
  ADD COLUMN runtime_thread_id VARCHAR(128) NULL AFTER status,
  ADD COLUMN runtime_run_id VARCHAR(128) NULL AFTER runtime_thread_id,
  ADD COLUMN reason TEXT NULL AFTER runtime_run_id,
  ADD KEY ix_poetry_agent_run_mandate (mandate_id),
  ADD KEY ix_poetry_agent_run_runtime (runtime_run_id);

INSERT INTO poetry_schema_version (version_no, description)
VALUES (8, 'Durable Poetry Studio task/run orchestration state; no foreign keys');
