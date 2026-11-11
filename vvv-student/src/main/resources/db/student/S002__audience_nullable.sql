-- S002：学段（audience）列放宽为可空——去掉学段的第一步（expand/contract 的 expand）。MySQL 5.6.40 兼容。
-- 只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`；DDL 在 MySQL 不可回滚。
-- 前置：S001 已执行。
--
-- 为什么：产品决定（2026-11-12）「我们不是讲课，也不关心年级，只关心对历史、对人物、对诗词的理解」。
-- 读者不再按小学/初中分版，新版 vvv-student 不再读写 audience。
--
-- 为什么分两步：student_session.audience 是 NOT NULL 且没有默认值。
--   - 先删列再部署新代码 → 旧代码写 audience 会报「Unknown column」；
--   - 先部署新代码再删列 → 新代码的 INSERT 不带 audience，在 STRICT 模式下报「doesn't have a default value」。
--   放宽为可空后，新旧代码都能写，部署之间没有失败窗口。列真正删除在 S003。
--
-- ===== 顺序 =====
--   1) 执行本文件（S002）
--   2) 部署新 vvv-student（不读写 audience）
--   3) 确认旧版本已全部下线后，执行 S003__drop_audience.sql
--
-- ===== 执行前只读检查 =====
--   SELECT version_no FROM student_schema_version ORDER BY version_no;   -- 含 1，不含 2
--   SHOW COLUMNS FROM student_session LIKE 'audience';                   -- Null 列为 NO
--
-- ===== 执行后核对 =====
--   SHOW COLUMNS FROM student_device  LIKE 'audience';   -- Null=YES, Default=NULL
--   SHOW COLUMNS FROM student_session LIKE 'audience';   -- Null=YES, Default=NULL
--
-- 回滚：recovery/S002_rollback.sql

ALTER TABLE student_device  MODIFY audience VARCHAR(16) NULL DEFAULT NULL;

ALTER TABLE student_session MODIFY audience VARCHAR(16) NULL DEFAULT NULL;

INSERT INTO student_schema_version (version_no, description)
SELECT 2, 'audience nullable (step 1 of 2: reader is not split by grade)'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM student_schema_version WHERE version_no = 2);
