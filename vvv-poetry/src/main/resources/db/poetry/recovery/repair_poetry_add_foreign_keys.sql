-- recovery 修复件：重建 poetry_* 表全部外键（回滚件）（2026-11-22，真库执行后登记）。
--
-- ===== 为什么 =====
-- 远端库（mysql.sspacee.com:6666/vpn，MySQL 8.0.46）的 poetry_* 表建于 11-06 初版，
-- 当时 schema 带 42 条外键；V002 起的迁移头注释明文「刻意没有外键」（MySQL 5.6 备份/
-- 恢复约束下的既定设计），V022 首次在真库执行即触发 ERROR 1452 外键约束失败——
-- 库与迁移文件的 schema 漂移，只有真库执行才暴露。本件是其逆操作：按删除时抓取的精确定义重建全部 42 条。
--
-- ===== 本件改什么，不改什么 =====
-- 改：仅重建 42 条 FOREIGN KEY 约束（定义逐条取自删除前 information_schema 快照）。
-- 不改：任何数据行、任何列、任何索引。完整性由 audit-migrations.py 在文件层把关。
--
-- ===== 回滚 =====
-- 同目录 repair_poetry_add_foreign_keys.sql 按本件生成时的精确定义重建全部 42 条。
ALTER TABLE `poetry_annotation` ADD CONSTRAINT `poetry_annotation_ibfk_1` FOREIGN KEY (`line_seq`,`version_id`) REFERENCES ` p o e t r y _ t e x t _ l i n e ` ( ` l i n e _ s e q ` , ` v e r s i o n _ i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_annotation` ADD CONSTRAINT `poetry_annotation_ibfk_2` FOREIGN KEY (`claim_id`) REFERENCES ` p o e t r y _ c l a i m ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_background` ADD CONSTRAINT `poetry_background_ibfk_1` FOREIGN KEY (`id`) REFERENCES ` p o e t r y _ c o n t e n t ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_background` ADD CONSTRAINT `poetry_background_ibfk_2` FOREIGN KEY (`work_id`) REFERENCES ` p o e t r y _ w o r k ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_background` ADD CONSTRAINT `poetry_background_ibfk_3` FOREIGN KEY (`claim_id`) REFERENCES ` p o e t r y _ c l a i m ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_background_line` ADD CONSTRAINT `poetry_background_line_ibfk_1` FOREIGN KEY (`background_id`) REFERENCES ` p o e t r y _ b a c k g r o u n d ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_background_line` ADD CONSTRAINT `poetry_background_line_ibfk_2` FOREIGN KEY (`version_id`,`line_seq`) REFERENCES ` p o e t r y _ t e x t _ l i n e ` ( ` v e r s i o n _ i d ` , ` l i n e _ s e q ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_citation` ADD CONSTRAINT `poetry_citation_ibfk_1` FOREIGN KEY (`claim_id`) REFERENCES ` p o e t r y _ c l a i m ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_citation` ADD CONSTRAINT `poetry_citation_ibfk_2` FOREIGN KEY (`source_id`) REFERENCES ` p o e t r y _ s o u r c e ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_claim` ADD CONSTRAINT `poetry_claim_ibfk_1` FOREIGN KEY (`subject_id`) REFERENCES ` p o e t r y _ c o n t e n t ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_claim_selection` ADD CONSTRAINT `poetry_claim_selection_ibfk_1` FOREIGN KEY (`subject_id`) REFERENCES ` p o e t r y _ c o n t e n t ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_claim_selection` ADD CONSTRAINT `poetry_claim_selection_ibfk_2` FOREIGN KEY (`claim_id`) REFERENCES ` p o e t r y _ c l a i m ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_dynasty` ADD CONSTRAINT `poetry_dynasty_ibfk_1` FOREIGN KEY (`id`) REFERENCES ` p o e t r y _ c o n t e n t ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_event` ADD CONSTRAINT `poetry_event_ibfk_1` FOREIGN KEY (`place_id`) REFERENCES ` p o e t r y _ p l a c e ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_event` ADD CONSTRAINT `poetry_event_ibfk_2` FOREIGN KEY (`id`) REFERENCES ` p o e t r y _ c o n t e n t ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_experience` ADD CONSTRAINT `poetry_experience_ibfk_1` FOREIGN KEY (`person_id`) REFERENCES ` p o e t r y _ p e r s o n ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_experience` ADD CONSTRAINT `poetry_experience_ibfk_2` FOREIGN KEY (`event_id`) REFERENCES ` p o e t r y _ e v e n t ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_experience` ADD CONSTRAINT `poetry_experience_ibfk_3` FOREIGN KEY (`place_id`) REFERENCES ` p o e t r y _ p l a c e ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_experience` ADD CONSTRAINT `poetry_experience_ibfk_4` FOREIGN KEY (`id`) REFERENCES ` p o e t r y _ c o n t e n t ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_period` ADD CONSTRAINT `poetry_period_ibfk_1` FOREIGN KEY (`dynasty_id`) REFERENCES ` p o e t r y _ d y n a s t y ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_period` ADD CONSTRAINT `poetry_period_ibfk_2` FOREIGN KEY (`parent_id`) REFERENCES ` p o e t r y _ p e r i o d ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_period` ADD CONSTRAINT `poetry_period_ibfk_3` FOREIGN KEY (`id`) REFERENCES ` p o e t r y _ c o n t e n t ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_person` ADD CONSTRAINT `poetry_person_ibfk_1` FOREIGN KEY (`dynasty_id`) REFERENCES ` p o e t r y _ d y n a s t y ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_person` ADD CONSTRAINT `poetry_person_ibfk_2` FOREIGN KEY (`id`) REFERENCES ` p o e t r y _ c o n t e n t ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_place` ADD CONSTRAINT `poetry_place_ibfk_1` FOREIGN KEY (`id`) REFERENCES ` p o e t r y _ c o n t e n t ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_relation` ADD CONSTRAINT `poetry_relation_ibfk_1` FOREIGN KEY (`subject_id`) REFERENCES ` p o e t r y _ c o n t e n t ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_relation` ADD CONSTRAINT `poetry_relation_ibfk_2` FOREIGN KEY (`object_id`) REFERENCES ` p o e t r y _ c o n t e n t ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_relation` ADD CONSTRAINT `poetry_relation_ibfk_3` FOREIGN KEY (`claim_id`) REFERENCES ` p o e t r y _ c l a i m ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_text_line` ADD CONSTRAINT `poetry_text_line_ibfk_1` FOREIGN KEY (`version_id`) REFERENCES ` p o e t r y _ t e x t _ v e r s i o n ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_text_version` ADD CONSTRAINT `poetry_text_version_ibfk_1` FOREIGN KEY (`work_id`) REFERENCES ` p o e t r y _ w o r k ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_text_version` ADD CONSTRAINT `poetry_text_version_ibfk_2` FOREIGN KEY (`source_id`) REFERENCES ` p o e t r y _ s o u r c e ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_textbook_work` ADD CONSTRAINT `poetry_textbook_work_ibfk_1` FOREIGN KEY (`textbook_id`) REFERENCES ` p o e t r y _ t e x t b o o k ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_textbook_work` ADD CONSTRAINT `poetry_textbook_work_ibfk_2` FOREIGN KEY (`work_id`) REFERENCES ` p o e t r y _ w o r k ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_textbook_work` ADD CONSTRAINT `poetry_textbook_work_ibfk_3` FOREIGN KEY (`version_id`) REFERENCES ` p o e t r y _ t e x t _ v e r s i o n ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_work` ADD CONSTRAINT `poetry_work_ibfk_1` FOREIGN KEY (`dynasty_id`) REFERENCES ` p o e t r y _ d y n a s t y ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_work` ADD CONSTRAINT `poetry_work_ibfk_2` FOREIGN KEY (`creation_place_id`) REFERENCES ` p o e t r y _ p l a c e ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_work` ADD CONSTRAINT `poetry_work_ibfk_3` FOREIGN KEY (`id`) REFERENCES ` p o e t r y _ c o n t e n t ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_work_author` ADD CONSTRAINT `poetry_work_author_ibfk_1` FOREIGN KEY (`work_id`) REFERENCES ` p o e t r y _ w o r k ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_work_author` ADD CONSTRAINT `poetry_work_author_ibfk_2` FOREIGN KEY (`person_id`) REFERENCES ` p o e t r y _ p e r s o n ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `poetry_work_author` ADD CONSTRAINT `poetry_work_author_ibfk_3` FOREIGN KEY (`claim_id`) REFERENCES ` p o e t r y _ c l a i m ` ( ` i d ` ) ON DELETE NO ACTION ON UPDATE NO ACTION;
