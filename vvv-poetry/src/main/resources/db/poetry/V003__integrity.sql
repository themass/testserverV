-- V003: foundation hardening. Apply AFTER V001 (and after V002 if it was applied).
-- Target syntax: MySQL 5.6+. The deployed MySQL version MUST be verified before applying.
-- DDL is NOT transactional in MySQL: run one statement at a time, stop on the first error,
-- never use `mysql --force`. Take a backup first.
--
-- Why this file exists (decisions taken 2026-11-06, see docs/poetry/data-model.md section 8):
--   1. one background = one layer + one body (primary_text/middle_text contradicted the
--      four-layer situational model: SCENE / CITY / WORLD / PERSON)
--   2. append-only review history, so "who approved which revision and why" is answerable
--   3. THEME entity + membership, so the timeline can become a stayable cultural space
--      instead of a flat list
--   4. coverage declared as DATA, not as a string hardcoded in Java
--   5. source kind/reliability and background audience, so review can be graded by stage
-- Still NO foreign keys by project rule; audit_integrity_checks.sql is the substitute.
-- NOTE: no column here is NOT NULL-without-default, so existing rows are untouched.

-- 1. background: one layer, one body text, plus audience
ALTER TABLE poetry_background ADD COLUMN body_text TEXT AFTER layer;
ALTER TABLE poetry_background ADD COLUMN audience VARCHAR(16) AFTER body_text;
-- primary_text / middle_text are retired. They were never populated (0 background rows exist).
-- If a database already has background rows, back them up before the two statements below:
--   INSERT INTO ... SELECT id, primary_text, middle_text FROM poetry_background;
ALTER TABLE poetry_background DROP COLUMN primary_text;
ALTER TABLE poetry_background DROP COLUMN middle_text;

-- 2. source grading (nullable on purpose: a row without grading can never become VERIFIED,
--    which audit check C5_verified_source_without_grading enforces)
ALTER TABLE poetry_source ADD COLUMN source_kind VARCHAR(24) AFTER rights_note;
ALTER TABLE poetry_source ADD COLUMN reliability VARCHAR(16) AFTER source_kind;
ALTER TABLE poetry_source ADD KEY ix_poetry_source_grading (source_kind, verification_status);

-- 3. place hierarchy (Tang dynasty circuit/prefecture/county -> modern name).
--    Structure only: no read path uses it yet. parent_id references poetry_place.id by convention.
ALTER TABLE poetry_place ADD COLUMN parent_id VARCHAR(64) COLLATE utf8mb4_bin AFTER modern_name;
ALTER TABLE poetry_place ADD KEY ix_poetry_place_parent (parent_id);

-- 4. append-only review history. Never UPDATE or DELETE these rows; a new decision is a new row.
CREATE TABLE poetry_review_log (
  id BIGINT NOT NULL AUTO_INCREMENT,
  subject_table VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  subject_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  subject_revision INT NOT NULL,
  decision VARCHAR(24) NOT NULL,
  reviewer VARCHAR(100) NOT NULL,
  note TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_poetry_review_log_subject (subject_table, subject_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. coverage declaration per entity type. This is what the timeline returns as "what is
--    covered here"; absence of data means NOT COVERED YET, not "nothing happened".
CREATE TABLE poetry_coverage (
  id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  entity_type VARCHAR(24) NOT NULL,
  from_year INT NOT NULL,
  to_year INT NOT NULL,
  coverage_kind VARCHAR(16) NOT NULL DEFAULT 'PARTIAL',
  status VARCHAR(16) NOT NULL DEFAULT 'DRAFT',
  note TEXT,
  updated_by VARCHAR(100),
  updated_at DATETIME,
  PRIMARY KEY (id),
  KEY ix_poetry_coverage_range (status, entity_type, from_year, to_year)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. THEME: a thread a student can stay on (e.g. the An Lushan Rebellion line).
--    A theme is a poetry_content row (entity_type='THEME') plus this child row.
CREATE TABLE poetry_theme (
  id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  period_scope VARCHAR(64) COLLATE utf8mb4_bin,
  PRIMARY KEY (id),
  KEY ix_poetry_theme_period_scope (period_scope)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_theme_item (
  theme_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  item_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  ordinal INT NOT NULL,
  item_role VARCHAR(16) NOT NULL DEFAULT 'MEMBER',
  note TEXT,
  PRIMARY KEY (theme_id, item_id),
  UNIQUE KEY uk_poetry_theme_item_ordinal (theme_id, ordinal),
  KEY ix_poetry_theme_item_item (item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO poetry_schema_version (version_no, description)
VALUES (3, 'Background single body+audience, source grading, place parent, review log, coverage, theme');
