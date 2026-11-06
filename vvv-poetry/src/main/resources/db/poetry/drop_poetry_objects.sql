-- Rollback helper for a DEV database only. Drops every poetry_* object created by
-- V001..V004. There is no UNDO in SQL for DDL, so this is the only way back, which is
-- why migrations must be run on a database you have backed up (or a scratch schema).
-- Child/link tables first, then content, then version bookkeeping. Order is cosmetic
-- (no foreign keys exist) but keeps the output readable if a statement fails.
DROP TABLE IF EXISTS poetry_script_asset;
DROP TABLE IF EXISTS poetry_script;
DROP TABLE IF EXISTS poetry_asset;
DROP TABLE IF EXISTS poetry_review_log;
DROP TABLE IF EXISTS poetry_coverage;
DROP TABLE IF EXISTS poetry_theme_item;
DROP TABLE IF EXISTS poetry_theme;
DROP TABLE IF EXISTS poetry_textbook_work;
DROP TABLE IF EXISTS poetry_textbook;
DROP TABLE IF EXISTS poetry_annotation;
DROP TABLE IF EXISTS poetry_background_line;
DROP TABLE IF EXISTS poetry_background;
DROP TABLE IF EXISTS poetry_text_line;
DROP TABLE IF EXISTS poetry_text_version;
DROP TABLE IF EXISTS poetry_work_author;
DROP TABLE IF EXISTS poetry_relation;
DROP TABLE IF EXISTS poetry_claim_selection;
DROP TABLE IF EXISTS poetry_citation;
DROP TABLE IF EXISTS poetry_claim;
DROP TABLE IF EXISTS poetry_source;
DROP TABLE IF EXISTS poetry_work;
DROP TABLE IF EXISTS poetry_experience;
DROP TABLE IF EXISTS poetry_event;
DROP TABLE IF EXISTS poetry_person;
DROP TABLE IF EXISTS poetry_place;
DROP TABLE IF EXISTS poetry_period;
DROP TABLE IF EXISTS poetry_dynasty;
DROP TABLE IF EXISTS poetry_content;
DROP TABLE IF EXISTS poetry_schema_version;
