-- recovery 修复件：移除 poetry_* 表全部外键（2026-11-22，真库执行后登记）。
--
-- ===== 为什么 =====
-- 远端库（mysql.sspacee.com:6666/vpn，MySQL 8.0.46）的 poetry_* 表建于 11-06 初版，
-- 当时 schema 带 42 条外键；V002 起的迁移头注释明文「刻意没有外键」（MySQL 5.6 备份/
-- 恢复约束下的既定设计），V022 首次在真库执行即触发 ERROR 1452 外键约束失败——
-- 库与迁移文件的 schema 漂移，只有真库执行才暴露。本件把库拉回文件声明的形状。
--
-- ===== 本件改什么，不改什么 =====
-- 改：仅删 42 条 FOREIGN KEY 约束（DROP FOREIGN KEY 不删索引、不动数据）。
-- 不改：任何数据行、任何列、任何索引。完整性由 audit-migrations.py 在文件层把关。
--
-- ===== 回滚 =====
-- 同目录 repair_poetry_add_foreign_keys.sql 按本件生成时的精确定义重建全部 42 条。
ALTER TABLE `poetry_annotation` DROP FOREIGN KEY `poetry_annotation_ibfk_1`;
ALTER TABLE `poetry_annotation` DROP FOREIGN KEY `poetry_annotation_ibfk_2`;
ALTER TABLE `poetry_background` DROP FOREIGN KEY `poetry_background_ibfk_1`;
ALTER TABLE `poetry_background` DROP FOREIGN KEY `poetry_background_ibfk_2`;
ALTER TABLE `poetry_background` DROP FOREIGN KEY `poetry_background_ibfk_3`;
ALTER TABLE `poetry_background_line` DROP FOREIGN KEY `poetry_background_line_ibfk_1`;
ALTER TABLE `poetry_background_line` DROP FOREIGN KEY `poetry_background_line_ibfk_2`;
ALTER TABLE `poetry_citation` DROP FOREIGN KEY `poetry_citation_ibfk_1`;
ALTER TABLE `poetry_citation` DROP FOREIGN KEY `poetry_citation_ibfk_2`;
ALTER TABLE `poetry_claim` DROP FOREIGN KEY `poetry_claim_ibfk_1`;
ALTER TABLE `poetry_claim_selection` DROP FOREIGN KEY `poetry_claim_selection_ibfk_1`;
ALTER TABLE `poetry_claim_selection` DROP FOREIGN KEY `poetry_claim_selection_ibfk_2`;
ALTER TABLE `poetry_dynasty` DROP FOREIGN KEY `poetry_dynasty_ibfk_1`;
ALTER TABLE `poetry_event` DROP FOREIGN KEY `poetry_event_ibfk_1`;
ALTER TABLE `poetry_event` DROP FOREIGN KEY `poetry_event_ibfk_2`;
ALTER TABLE `poetry_experience` DROP FOREIGN KEY `poetry_experience_ibfk_1`;
ALTER TABLE `poetry_experience` DROP FOREIGN KEY `poetry_experience_ibfk_2`;
ALTER TABLE `poetry_experience` DROP FOREIGN KEY `poetry_experience_ibfk_3`;
ALTER TABLE `poetry_experience` DROP FOREIGN KEY `poetry_experience_ibfk_4`;
ALTER TABLE `poetry_period` DROP FOREIGN KEY `poetry_period_ibfk_1`;
ALTER TABLE `poetry_period` DROP FOREIGN KEY `poetry_period_ibfk_2`;
ALTER TABLE `poetry_period` DROP FOREIGN KEY `poetry_period_ibfk_3`;
ALTER TABLE `poetry_person` DROP FOREIGN KEY `poetry_person_ibfk_1`;
ALTER TABLE `poetry_person` DROP FOREIGN KEY `poetry_person_ibfk_2`;
ALTER TABLE `poetry_place` DROP FOREIGN KEY `poetry_place_ibfk_1`;
ALTER TABLE `poetry_relation` DROP FOREIGN KEY `poetry_relation_ibfk_1`;
ALTER TABLE `poetry_relation` DROP FOREIGN KEY `poetry_relation_ibfk_2`;
ALTER TABLE `poetry_relation` DROP FOREIGN KEY `poetry_relation_ibfk_3`;
ALTER TABLE `poetry_text_line` DROP FOREIGN KEY `poetry_text_line_ibfk_1`;
ALTER TABLE `poetry_text_version` DROP FOREIGN KEY `poetry_text_version_ibfk_1`;
ALTER TABLE `poetry_text_version` DROP FOREIGN KEY `poetry_text_version_ibfk_2`;
ALTER TABLE `poetry_textbook_work` DROP FOREIGN KEY `poetry_textbook_work_ibfk_1`;
ALTER TABLE `poetry_textbook_work` DROP FOREIGN KEY `poetry_textbook_work_ibfk_2`;
ALTER TABLE `poetry_textbook_work` DROP FOREIGN KEY `poetry_textbook_work_ibfk_3`;
ALTER TABLE `poetry_work` DROP FOREIGN KEY `poetry_work_ibfk_1`;
ALTER TABLE `poetry_work` DROP FOREIGN KEY `poetry_work_ibfk_2`;
ALTER TABLE `poetry_work` DROP FOREIGN KEY `poetry_work_ibfk_3`;
ALTER TABLE `poetry_work_author` DROP FOREIGN KEY `poetry_work_author_ibfk_1`;
ALTER TABLE `poetry_work_author` DROP FOREIGN KEY `poetry_work_author_ibfk_2`;
ALTER TABLE `poetry_work_author` DROP FOREIGN KEY `poetry_work_author_ibfk_3`;--
-- ===== 执行记录 =====
-- 2026-11-22 01:3x 于 mysql.sspacee.com:6666/vpn（MySQL 8.0.46）执行。
