-- Rollback helper for a DEV database only. Drops every poetry_* object created by
-- V001..V009 (agent tables V007/V008, Studio governance V009 included; the V009 audit-trail
-- tables are dropped only if they still exist under their original names, not if renamed by the rollback). There is no UNDO in SQL for DDL, so this is the only way back, which is
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
-- V007/V008/V009 agent and Studio tables (added after the original list above; these were missing before).
DROP TABLE IF EXISTS poetry_studio_check_log;
DROP TABLE IF EXISTS poetry_agent_proposal_item;
DROP TABLE IF EXISTS poetry_agent_compile_request;
DROP TABLE IF EXISTS poetry_agent_event;
DROP TABLE IF EXISTS poetry_agent_tool_receipt;
DROP TABLE IF EXISTS poetry_agent_review;
DROP TABLE IF EXISTS poetry_agent_proposal;
DROP TABLE IF EXISTS poetry_agent_mandate;
DROP TABLE IF EXISTS poetry_agent_run;
DROP TABLE IF EXISTS poetry_agent_task;
DROP TABLE IF EXISTS poetry_agent_profile_version;
DROP TABLE IF EXISTS poetry_schema_version;
