-- S003 回滚：把 audience 列加回来（可空），回到 S002 之后的状态。删掉的值无法恢复。
ALTER TABLE student_device  ADD COLUMN audience VARCHAR(16) NULL DEFAULT NULL AFTER key_sha256;
ALTER TABLE student_session ADD COLUMN audience VARCHAR(16) NULL DEFAULT NULL AFTER visited;
DELETE FROM student_schema_version WHERE version_no = 3;
