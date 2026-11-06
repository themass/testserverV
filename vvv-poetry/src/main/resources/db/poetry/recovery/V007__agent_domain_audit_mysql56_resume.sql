-- One-time recovery for the November 6, 2026 V007 attempt on MySQL 5.6.40.
-- Run ONLY when the first five poetry_agent_* tables were created but the migration stopped
-- at poetry_agent_tool_receipt because utf8mb4 made the original 48+200 unique key exceed
-- MySQL 5.6's 767-byte limit. Do not use this file for clean schemas; run V007 instead.
-- No foreign keys are created.

CREATE TABLE IF NOT EXISTS poetry_agent_tool_receipt (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  operation VARCHAR(48) NOT NULL,
  idempotency_key VARCHAR(128) COLLATE utf8mb4_bin NOT NULL,
  run_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  mandate_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  result_ref VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_poetry_agent_tool_receipt (operation, idempotency_key),
  KEY ix_poetry_agent_tool_receipt_run (run_id, mandate_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS poetry_agent_event (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  run_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  event_type VARCHAR(64) NOT NULL,
  payload_json LONGTEXT,
  occurred_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY ix_poetry_agent_event_run (run_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS poetry_agent_profile_version (
  fingerprint VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  profile_name VARCHAR(64) NOT NULL,
  manifest_json LONGTEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS poetry_agent_compile_request (
  id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  work_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  script_version VARCHAR(128) NOT NULL,
  run_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  mandate_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  status VARCHAR(24) NOT NULL,
  reason TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY ix_poetry_agent_compile_work (work_id, status),
  KEY ix_poetry_agent_compile_mandate (run_id, mandate_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO poetry_schema_version (version_no, description)
SELECT 6, 'Media and scene-script base tables; no foreign keys' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no=6);

INSERT INTO poetry_schema_version (version_no, description)
SELECT 7, 'Agent domain records: mandate, draft proposal, review, receipt and compiler eligibility; no foreign keys' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no=7);
