-- V001: poetry content foundation. Apply explicitly to a backed-up, selected database.
-- MySQL 5.6+ syntax target; exact deployed version MUST be verified before applying.
-- No JSON, CHECK, generated columns, window functions or changes to existing tables.
-- DDL is not transactional in MySQL. Stop on the first error; never use mysql --force.
--
-- PROJECT RULE: no FOREIGN KEY in DDL and none in application code. Referential integrity is
-- a documented convention enforced by three things instead:
--   1. Read side: every SELECT joins the parent rows and re-checks publish/review/source state,
--      so a dangling or mismatched reference can never reach a student (fail closed).
--   2. Insert order convention: poetry_content first, then the entity child row, then link rows.
--   3. audit_integrity_checks.sql: run after every data change; all checks must return 0.
-- Because FOREIGN KEY is removed, MySQL no longer auto-creates indexes on reference columns.
-- Every reference column that is joined gets an explicit KEY below.
-- entity_type is not cross-checked by the database: a child row MUST match its poetry_content
-- entity_type by convention, verified by audit check 'type_mismatch_*'.

CREATE TABLE poetry_schema_version (
version_no INT NOT NULL PRIMARY KEY,
  description VARCHAR(200) NOT NULL,
  applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_content (
id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  entity_type VARCHAR(24) NOT NULL,
  slug VARCHAR(120) COLLATE utf8mb4_bin NOT NULL,
  title VARCHAR(200) NOT NULL,
  summary TEXT,
  start_year INT,
  end_year INT,
  time_precision VARCHAR(16) NOT NULL DEFAULT 'UNKNOWN',
  status VARCHAR(16) NOT NULL DEFAULT 'DRAFT',
  revision INT NOT NULL DEFAULT 1,
  reviewed_by VARCHAR(100),
  reviewed_at DATETIME,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_poetry_content_slug (entity_type, slug),
  KEY ix_poetry_content_public (status, entity_type, start_year, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_dynasty (
id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_period (
id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  dynasty_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  parent_id VARCHAR(64) COLLATE utf8mb4_bin,
  KEY ix_poetry_period_dynasty (dynasty_id),
  KEY ix_poetry_period_parent (parent_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_place (
id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  modern_name VARCHAR(200),
  latitude DECIMAL(10,7),
  longitude DECIMAL(10,7),
  coordinate_system VARCHAR(16)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_person (
id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  dynasty_id VARCHAR(64) COLLATE utf8mb4_bin,
  courtesy_name VARCHAR(100),
  KEY ix_poetry_person_dynasty (dynasty_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_event (
id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  place_id VARCHAR(64) COLLATE utf8mb4_bin,
  KEY ix_poetry_event_place (place_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_experience (
id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  person_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  event_id VARCHAR(64) COLLATE utf8mb4_bin,
  place_id VARCHAR(64) COLLATE utf8mb4_bin,
  KEY ix_poetry_experience_person (person_id),
  KEY ix_poetry_experience_event (event_id),
  KEY ix_poetry_experience_place (place_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_work (
id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  dynasty_id VARCHAR(64) COLLATE utf8mb4_bin,
  creation_place_id VARCHAR(64) COLLATE utf8mb4_bin,
  genre VARCHAR(32),
  KEY ix_poetry_work_dynasty (dynasty_id),
  KEY ix_poetry_work_creation_place (creation_place_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_source (
id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  title VARCHAR(300) NOT NULL,
  author VARCHAR(200),
  edition VARCHAR(300),
  url VARCHAR(1000),
  rights_note TEXT,
  verification_status VARCHAR(16) NOT NULL DEFAULT 'PENDING',
  verified_by VARCHAR(100),
  verified_at DATETIME,
  KEY ix_poetry_source_verification (verification_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_claim (
id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  subject_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  property_key VARCHAR(64) NOT NULL,
  value_text TEXT NOT NULL,
  claim_kind VARCHAR(24) NOT NULL,
  certainty VARCHAR(24) NOT NULL DEFAULT 'UNKNOWN',
  dramatization_labeled TINYINT NOT NULL DEFAULT 0,
  status VARCHAR(16) NOT NULL DEFAULT 'DRAFT',
  reviewed_by VARCHAR(100),
  reviewed_at DATETIME,
  KEY ix_poetry_claim_subject (subject_id, status, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_citation (
claim_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  source_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  locator VARCHAR(300) NOT NULL,
  evidence_excerpt TEXT,
  PRIMARY KEY (claim_id, source_id),
  KEY ix_poetry_citation_source (source_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_claim_selection (
subject_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  property_key VARCHAR(64) NOT NULL,
  claim_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  PRIMARY KEY (subject_id, property_key),
  KEY ix_poetry_claim_selection_claim (claim_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_relation (
id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  subject_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  predicate VARCHAR(40) NOT NULL,
  object_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  claim_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  UNIQUE KEY uk_poetry_relation (subject_id, predicate, object_id),
  KEY ix_poetry_relation_object (object_id),
  KEY ix_poetry_relation_claim (claim_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_work_author (
work_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  person_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  attribution VARCHAR(24) NOT NULL,
  claim_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  PRIMARY KEY (work_id, person_id),
  KEY ix_poetry_work_author_person (person_id),
  KEY ix_poetry_work_author_claim (claim_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_text_version (
id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  work_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  version_code VARCHAR(64) NOT NULL,
  label VARCHAR(200) NOT NULL,
  script VARCHAR(24) NOT NULL,
  source_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  source_locator VARCHAR(300) NOT NULL,
  status VARCHAR(16) NOT NULL DEFAULT 'DRAFT',
  reviewed_by VARCHAR(100),
  reviewed_at DATETIME,
  UNIQUE KEY uk_poetry_text_version (work_id, version_code),
  KEY ix_poetry_text_version_source (source_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_text_line (
version_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  line_seq INT NOT NULL,
  content VARCHAR(500) NOT NULL,
  pinyin VARCHAR(1000),
  PRIMARY KEY (version_id, line_seq)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_background (
id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  work_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  layer VARCHAR(24) NOT NULL,
  claim_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  primary_text TEXT,
  middle_text TEXT,
  KEY ix_poetry_background_work (work_id),
  KEY ix_poetry_background_claim (claim_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_background_line (
background_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  version_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  line_seq INT NOT NULL,
  PRIMARY KEY (background_id, version_id, line_seq),
  KEY ix_poetry_background_line_version (version_id, line_seq)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_annotation (
id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  version_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  line_seq INT NOT NULL,
  annotation_kind VARCHAR(24) NOT NULL,
  audience VARCHAR(16) NOT NULL,
  content TEXT NOT NULL,
  claim_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  KEY ix_poetry_annotation_line (version_id, line_seq),
  KEY ix_poetry_annotation_claim (claim_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_textbook (
id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  publisher VARCHAR(200) NOT NULL,
  edition VARCHAR(100) NOT NULL,
  school_stage VARCHAR(16) NOT NULL,
  grade_no INT NOT NULL,
  volume VARCHAR(24) NOT NULL,
  isbn VARCHAR(32),
  verification_status VARCHAR(16) NOT NULL DEFAULT 'PENDING'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_textbook_work (
textbook_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  work_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  version_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  unit_label VARCHAR(100),
  lesson_label VARCHAR(100),
  page_locator VARCHAR(100) NOT NULL,
  PRIMARY KEY (textbook_id, work_id),
  KEY ix_poetry_textbook_work_work (work_id),
  KEY ix_poetry_textbook_work_version (version_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO poetry_schema_version (version_no, description) VALUES (1, 'Content foundation schema, no foreign keys');
