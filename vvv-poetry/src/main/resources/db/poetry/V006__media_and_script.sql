-- V006: media + script side of the content base. Apply AFTER V001/V003.
-- Target: MySQL 5.6.40 (measured version of the deployed server). DDL is not transactional:
-- run on a backed-up database, one statement at a time, never with `mysql --force`.
--
-- Why these three tables exist now (see docs/specs/2026-11-06-qijing-script-dsl.md §4-§5):
--   1. assets must be content-addressed (hash) or offline caching, rollback and "which build
--      produced this image" are unrecoverable later;
--   2. an asset without `meaning` (which line it helps a learner understand) is not allowed to
--      exist — that is rule R10 of the bundle compiler, written as a NOT NULL column;
--   3. the scene script needs a home in the base so "which script version shipped which bundle"
--      is answerable from the database, not from a deploy log.
-- Still NO foreign keys by project rule; audit_integrity_checks.sql C8 is the substitute.

CREATE TABLE poetry_asset (
  id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  kind VARCHAR(24) NOT NULL,                       -- illustration/map/character/audio/voice/subtitle/video
  level VARCHAR(8) NOT NULL,                       -- L0 text .. L4 realtime 3D
  uri VARCHAR(500) NOT NULL,                       -- object key in storage, never a signed URL
  hash VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,   -- content hash: the delivery address
  bytes BIGINT NOT NULL DEFAULT 0,
  fallback_id VARCHAR(64) COLLATE utf8mb4_bin,     -- degradation chain; NULL only for L0 rows
  meaning TEXT NOT NULL,                           -- R10: what it explains, or it must not exist
  workflow_ref VARCHAR(300),                       -- which pipeline/version produced it
  human_fix TINYINT NOT NULL DEFAULT 0,
  rights_origin VARCHAR(100) NOT NULL,
  rights_license VARCHAR(50) NOT NULL,
  status VARCHAR(16) NOT NULL DEFAULT 'DRAFT',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_poetry_asset_hash (hash),
  KEY ix_poetry_asset_public (status, level, id),
  KEY ix_poetry_asset_fallback (fallback_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_script (
  id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  script_version VARCHAR(32) NOT NULL,
  schema_version VARCHAR(16) NOT NULL DEFAULT '1.0',
  work_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,          -- -> poetry_content.id (WORK)
  text_version_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,  -- -> poetry_text_version.id
  coverage_notice TEXT NOT NULL,                             -- R5: declared, never invented in a page
  bundle_hash VARCHAR(64) COLLATE utf8mb4_bin,               -- set only once the compiler produced it
  compiled_by VARCHAR(100),
  compiled_at DATETIME,
  status VARCHAR(16) NOT NULL DEFAULT 'DRAFT',
  revision INT NOT NULL DEFAULT 1,
  PRIMARY KEY (id, script_version),
  UNIQUE KEY uk_poetry_script_bundle (bundle_hash),
  KEY ix_poetry_script_work (work_id, status),
  KEY ix_poetry_script_text_version (text_version_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Which script version pulls which asset. Without this, "can I retire this voice model?" and
-- "how much will this scene cost to re-make?" are unanswerable questions.
CREATE TABLE poetry_script_asset (
  script_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  script_version VARCHAR(32) NOT NULL,
  asset_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  step VARCHAR(16) NOT NULL,                         -- read/arrive/meet/return/recite
  PRIMARY KEY (script_id, script_version, asset_id),
  KEY ix_poetry_script_asset_asset (asset_id),
  KEY ix_poetry_script_asset_script (script_id, script_version)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO poetry_schema_version (version_no, description)
VALUES (6, 'Media and scene-script base tables; no foreign keys');
