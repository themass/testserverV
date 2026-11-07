-- Rollback of S001. Destroys all anonymous learning records. Never run automatically.
-- Does not touch any poetry_* table.
DROP TABLE IF EXISTS student_gap;
DROP TABLE IF EXISTS student_event;
DROP TABLE IF EXISTS student_session;
DROP TABLE IF EXISTS student_device;
DROP TABLE IF EXISTS student_schema_version;
