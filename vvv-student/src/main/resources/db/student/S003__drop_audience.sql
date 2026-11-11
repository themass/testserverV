-- S003：删除学段（audience）列——去掉学段的第二步（contract）。MySQL 5.6.40 兼容。
-- 只写文件，由用户手工执行；DDL 不可回滚，执行前先备份。
-- 前置：S002 已执行，**且不读写 audience 的新版 vvv-student 已经全部上线、旧版本已全部下线**。
--   旧版本还在跑时执行本文件，旧版本写进度会报「Unknown column 'audience'」。
--
-- 一列不用的未成年人数据就不该存（数据最小化）。
--
-- ===== 执行前只读检查 =====
--   SELECT version_no FROM student_schema_version ORDER BY version_no;   -- 含 2，不含 3
--
-- ===== 执行后核对 =====
--   SHOW COLUMNS FROM student_device  LIKE 'audience';   -- 空
--   SHOW COLUMNS FROM student_session LIKE 'audience';   -- 空
--
-- 回滚：recovery/S003_rollback.sql（只能把列加回来，删掉的值找不回——它们本来也没有用处）

ALTER TABLE student_device  DROP COLUMN audience;

ALTER TABLE student_session DROP COLUMN audience;

INSERT INTO student_schema_version (version_no, description)
SELECT 3, 'drop audience (step 2 of 2)'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM student_schema_version WHERE version_no = 3);
