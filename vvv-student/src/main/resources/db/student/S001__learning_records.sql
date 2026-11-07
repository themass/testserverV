-- S001: anonymous learning records for the student app. NOT EXECUTED by any code or by the author.
-- Target: MySQL 5.6.40 (deployed). Rules honoured: no JSON, no CHECK, no generated columns,
-- no foreign keys; every single-column index key stays well under 767 bytes (utf8mb4: 4 bytes/char).
-- DDL is not transactional: back up first, run one statement at a time, never with `mysql --force`.
--
-- Privacy contract (see student-app/design/api-and-data.md section 2.3):
--   * No name, school, face, voiceprint, recording, device fingerprint, precise location, IP address.
--   * No free text from the learner: `ref` only ever holds an enumerated value or a small integer,
--     and the retell text a child types NEVER reaches the server (only point ids in student_gap).
--   * `student_device.id` is a random server-issued value; only the SHA-256 of the key is stored.
--   * Everything about one device is removable with a single DELETE /devices/me.
-- Table prefix `student_` keeps this family apart from `poetry_*` (content base) on the same server.

CREATE TABLE student_schema_version (
  version_no INT NOT NULL PRIMARY KEY,
  description VARCHAR(200) NOT NULL,
  applied_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE student_device (
  id VARCHAR(32) COLLATE utf8mb4_bin NOT NULL PRIMARY KEY,           -- random, server-issued, resettable
  key_sha256 CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, -- SHA-256 hex of the bearer key
  audience VARCHAR(16) NOT NULL DEFAULT 'PRIMARY',                    -- PRIMARY | JUNIOR, chosen by the learner
  consent_version VARCHAR(16) NOT NULL,                               -- which data notice was shown
  created_at DATETIME NOT NULL,
  last_seen_at DATETIME NOT NULL,
  UNIQUE KEY uk_student_device_key (key_sha256),
  KEY ix_student_device_seen (last_seen_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Where the learner stopped. No score, no rank, no streak: this exists only to resume.
CREATE TABLE student_session (
  device_id VARCHAR(32) COLLATE utf8mb4_bin NOT NULL,
  work_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  last_step VARCHAR(16) NOT NULL,                  -- read | arrive | meet | return | recite
  visited VARCHAR(40) NOT NULL,                    -- comma list of steps, e.g. 'read,arrive'
  audience VARCHAR(16) NOT NULL,
  entered_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  PRIMARY KEY (device_id, work_id),
  KEY ix_student_session_work (work_id, updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structured behaviour only. Whitelisted in EventValidator; see api-and-data.md section 2.2.
CREATE TABLE student_event (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  device_id VARCHAR(32) COLLATE utf8mb4_bin NOT NULL,
  work_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  step VARCHAR(16) NOT NULL,
  kind VARCHAR(24) NOT NULL,
  ref VARCHAR(24) NULL,                            -- enumerated value or small integer, never free text
  ms INT NULL,                                     -- dwell time for step_leave
  client_at DATETIME NULL,                         -- only kept when within a sane window of server time
  created_at DATETIME NOT NULL,
  KEY ix_student_event_device (device_id, created_at),
  KEY ix_student_event_work (work_id, kind, created_at),
  KEY ix_student_event_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Which retell points were / were not covered. Point ids only. Feeds the content gap board.
CREATE TABLE student_gap (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  device_id VARCHAR(32) COLLATE utf8mb4_bin NOT NULL,
  work_id VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  script_hash VARCHAR(64) COLLATE utf8mb4_bin NOT NULL,
  point_id VARCHAR(48) COLLATE utf8mb4_bin NOT NULL,
  state VARCHAR(8) NOT NULL,                       -- COVERED | MISSING
  created_at DATETIME NOT NULL,
  KEY ix_student_gap_device (device_id),
  KEY ix_student_gap_board (work_id, script_hash, point_id, state),
  KEY ix_student_gap_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO student_schema_version (version_no, description)
VALUES (1, 'Anonymous learning records: device, session, event, gap; no foreign keys');
