-- V007: Agent-domain audit trail. Apply AFTER V006 on a backed-up selected MySQL schema.
-- This migration deliberately contains NO FOREIGN KEY clauses. Association safety is supplied by
-- service-side checks, unique idempotency keys and the C9 audit queries appended below.
-- Proposal JSON is LONGTEXT rather than MySQL JSON because the deployed compatibility target is MySQL 5.6.

CREATE TABLE poetry_agent_task (
  id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  work_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  task_type VARCHAR(32) NOT NULL,
  requested_by VARCHAR(100) NOT NULL,
  status VARCHAR(24) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME,
  KEY ix_poetry_agent_task_work (work_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_agent_run (
  id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  task_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  runtime VARCHAR(32) NOT NULL,
  profile_fingerprint VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  status VARCHAR(24) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME,
  KEY ix_poetry_agent_run_task (task_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_agent_mandate (
  run_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  mandate_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  work_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  actor_role VARCHAR(32) NOT NULL,
  status VARCHAR(24) NOT NULL DEFAULT 'ACTIVE',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (run_id, mandate_id),
  KEY ix_poetry_agent_mandate_work (work_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_agent_proposal (
  id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  work_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  run_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  mandate_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  proposal_json LONGTEXT NOT NULL,
  status VARCHAR(24) NOT NULL DEFAULT 'DRAFT',
  review_status VARCHAR(24) NOT NULL DEFAULT 'PENDING',
  review_id VARCHAR(64) COLLATE utf8mb4_bin,
  reviewed_by VARCHAR(100),
  reviewed_at DATETIME,
  review_comment TEXT,
  created_by VARCHAR(64) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  applied_at DATETIME,
  KEY ix_poetry_agent_proposal_work (work_id, status, review_status),
  KEY ix_poetry_agent_proposal_mandate (run_id, mandate_id),
  UNIQUE KEY uk_poetry_agent_proposal_review (review_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_agent_review (
  id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  proposal_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  reviewer_id VARCHAR(100) NOT NULL,
  decision VARCHAR(24) NOT NULL,
  comment TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY ix_poetry_agent_review_proposal (proposal_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_agent_tool_receipt (
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

CREATE TABLE poetry_agent_event (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  run_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  event_type VARCHAR(64) NOT NULL,
  payload_json LONGTEXT,
  occurred_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY ix_poetry_agent_event_run (run_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_agent_profile_version (
  fingerprint VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  profile_name VARCHAR(64) NOT NULL,
  manifest_json LONGTEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_agent_compile_request (
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

-- V006 was deployed before its version-ledger row existed. Keep this repair idempotent so
-- V007 can safely close that historical ledger gap on the already-deployed schema.
INSERT INTO poetry_schema_version (version_no, description)
SELECT 6, 'Media and scene-script base tables; no foreign keys' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no=6);

INSERT INTO poetry_schema_version (version_no, description)
VALUES (7, 'Agent domain records: mandate, draft proposal, review, receipt and compiler eligibility; no foreign keys');
