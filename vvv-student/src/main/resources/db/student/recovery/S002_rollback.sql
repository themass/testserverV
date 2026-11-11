-- S002 回滚：把 audience 恢复为 S001 的定义。先回滚代码（回到读写 audience 的版本），再执行本文件。
-- 已有的 NULL 值先补成 'PRIMARY'，否则 MODIFY ... NOT NULL 会失败。
UPDATE student_device  SET audience = 'PRIMARY' WHERE audience IS NULL;
UPDATE student_session SET audience = 'PRIMARY' WHERE audience IS NULL;
ALTER TABLE student_device  MODIFY audience VARCHAR(16) NOT NULL DEFAULT 'PRIMARY';
ALTER TABLE student_session MODIFY audience VARCHAR(16) NOT NULL;
DELETE FROM student_schema_version WHERE version_no = 2;
