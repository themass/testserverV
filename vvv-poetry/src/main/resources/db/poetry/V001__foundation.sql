-- V001: poetry content foundation. Apply explicitly to a backed-up, selected database.
-- MySQL 5.6+ syntax target; exact deployed version MUST be verified before applying.
-- No JSON, CHECK, generated columns, window functions or changes to existing tables.
-- DDL is not transactional in MySQL. Stop on the first error; never use mysql --force.
-- Foreign keys use RESTRICT. Status/review and semantic constraints are application/audit responsibilities.

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
id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  
  FOREIGN KEY (id) REFERENCES poetry_content(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_period (
id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  dynasty_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  parent_id VARCHAR(64) COLLATE utf8mb4_bin,
  FOREIGN KEY (dynasty_id) REFERENCES poetry_dynasty(id),
  FOREIGN KEY (parent_id) REFERENCES poetry_period(id),
  FOREIGN KEY (id) REFERENCES poetry_content(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_place (
id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  modern_name VARCHAR(200),
  latitude DECIMAL(10,7),
  longitude DECIMAL(10,7),
  coordinate_system VARCHAR(16),
  FOREIGN KEY (id) REFERENCES poetry_content(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_person (
id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  dynasty_id VARCHAR(64) COLLATE utf8mb4_bin,
  courtesy_name VARCHAR(100),
  FOREIGN KEY (dynasty_id) REFERENCES poetry_dynasty(id),
  FOREIGN KEY (id) REFERENCES poetry_content(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_event (
id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  place_id VARCHAR(64) COLLATE utf8mb4_bin,
  FOREIGN KEY (place_id) REFERENCES poetry_place(id),
  FOREIGN KEY (id) REFERENCES poetry_content(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_experience (
id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  person_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  event_id VARCHAR(64) COLLATE utf8mb4_bin,
  place_id VARCHAR(64) COLLATE utf8mb4_bin,
  FOREIGN KEY (person_id) REFERENCES poetry_person(id),
  FOREIGN KEY (event_id) REFERENCES poetry_event(id),
  FOREIGN KEY (place_id) REFERENCES poetry_place(id),
  KEY ix_poetry_experience_person (person_id),
  FOREIGN KEY (id) REFERENCES poetry_content(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_work (
id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  dynasty_id VARCHAR(64) COLLATE utf8mb4_bin,
  creation_place_id VARCHAR(64) COLLATE utf8mb4_bin,
  genre VARCHAR(32),
  FOREIGN KEY (dynasty_id) REFERENCES poetry_dynasty(id),
  FOREIGN KEY (creation_place_id) REFERENCES poetry_place(id),
  FOREIGN KEY (id) REFERENCES poetry_content(id)
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
  verified_at DATETIME
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
  FOREIGN KEY (subject_id) REFERENCES poetry_content(id),
  KEY ix_poetry_claim_subject (subject_id, status, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_citation (
claim_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  source_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  locator VARCHAR(300) NOT NULL,
  evidence_excerpt TEXT,
  PRIMARY KEY (claim_id, source_id),
  FOREIGN KEY (claim_id) REFERENCES poetry_claim(id),
  FOREIGN KEY (source_id) REFERENCES poetry_source(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_claim_selection (
subject_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  property_key VARCHAR(64) NOT NULL,
  claim_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  PRIMARY KEY (subject_id, property_key),
  FOREIGN KEY (subject_id) REFERENCES poetry_content(id),
  FOREIGN KEY (claim_id) REFERENCES poetry_claim(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_relation (
id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  subject_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  predicate VARCHAR(40) NOT NULL,
  object_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  claim_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  FOREIGN KEY (subject_id) REFERENCES poetry_content(id),
  FOREIGN KEY (object_id) REFERENCES poetry_content(id),
  FOREIGN KEY (claim_id) REFERENCES poetry_claim(id),
  UNIQUE KEY uk_poetry_relation (subject_id, predicate, object_id),
  KEY ix_poetry_relation_object (object_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_work_author (
work_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  person_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  attribution VARCHAR(24) NOT NULL,
  claim_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  PRIMARY KEY (work_id, person_id),
  FOREIGN KEY (work_id) REFERENCES poetry_work(id),
  FOREIGN KEY (person_id) REFERENCES poetry_person(id),
  FOREIGN KEY (claim_id) REFERENCES poetry_claim(id)
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
  FOREIGN KEY (work_id) REFERENCES poetry_work(id),
  FOREIGN KEY (source_id) REFERENCES poetry_source(id),
  UNIQUE KEY uk_poetry_text_version (work_id, version_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_text_line (
version_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  line_seq INT NOT NULL,
  content VARCHAR(500) NOT NULL,
  pinyin VARCHAR(1000),
  PRIMARY KEY (version_id, line_seq),
  FOREIGN KEY (version_id) REFERENCES poetry_text_version(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_background (
id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  work_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  layer VARCHAR(24) NOT NULL,
  claim_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  primary_text TEXT,
  middle_text TEXT,
  FOREIGN KEY (id) REFERENCES poetry_content(id),
  FOREIGN KEY (work_id) REFERENCES poetry_work(id),
  FOREIGN KEY (claim_id) REFERENCES poetry_claim(id),
  KEY ix_poetry_background_work (work_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_background_line (
background_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  version_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  line_seq INT NOT NULL,
  PRIMARY KEY (background_id, version_id, line_seq),
  FOREIGN KEY (background_id) REFERENCES poetry_background(id),
  FOREIGN KEY (version_id, line_seq) REFERENCES poetry_text_line(version_id, line_seq)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE poetry_annotation (
id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,
  version_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  line_seq INT NOT NULL,
  annotation_kind VARCHAR(24) NOT NULL,
  audience VARCHAR(16) NOT NULL,
  content TEXT NOT NULL,
  claim_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  FOREIGN KEY (version_id, line_seq) REFERENCES poetry_text_line(version_id, line_seq),
  FOREIGN KEY (claim_id) REFERENCES poetry_claim(id)
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
  FOREIGN KEY (textbook_id) REFERENCES poetry_textbook(id),
  FOREIGN KEY (work_id) REFERENCES poetry_work(id),
  FOREIGN KEY (version_id) REFERENCES poetry_text_version(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO poetry_schema_version (version_no, description) VALUES (1, 'Content foundation schema');
