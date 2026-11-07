-- Retention for student_* tables. NOT scheduled and NOT executed by the application.
-- Run from an operator-owned job (or by hand) on a backed-up database. All times are UTC, matching how
-- the application writes them (UTC_TIMESTAMP()). For large tables add `LIMIT 5000` to the single-table
-- DELETEs and repeat (MySQL 5.6 supports LIMIT on single-table DELETE).
-- Policy (api-and-data.md section 2.3): events 90 days; gaps 180 days; inactive devices 180 days.

DELETE FROM student_event WHERE created_at < UTC_TIMESTAMP() - INTERVAL 90 DAY;
DELETE FROM student_gap   WHERE created_at < UTC_TIMESTAMP() - INTERVAL 180 DAY;

-- Inactive devices: remove dependants first (there are no foreign keys to do it for us).
-- The derived-table wrapper avoids MySQL's "can't specify target table in FROM clause" error.
DELETE FROM student_session WHERE device_id IN
  (SELECT id FROM (SELECT id FROM student_device WHERE last_seen_at < UTC_TIMESTAMP() - INTERVAL 180 DAY) t);
DELETE FROM student_event WHERE device_id IN
  (SELECT id FROM (SELECT id FROM student_device WHERE last_seen_at < UTC_TIMESTAMP() - INTERVAL 180 DAY) t);
DELETE FROM student_gap WHERE device_id IN
  (SELECT id FROM (SELECT id FROM student_device WHERE last_seen_at < UTC_TIMESTAMP() - INTERVAL 180 DAY) t);
DELETE FROM student_device WHERE last_seen_at < UTC_TIMESTAMP() - INTERVAL 180 DAY;
