-- V027 精确回滚：只删 V027 插入的行（id 全枚举）。work-t300-231 本体是 V018 的行，绝不删；
-- 共用 source 行（jiutangshu-dufu/xintangshu-wenyi/tongjian-events）都不删。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-yy-scene', 'claim-bg-yy-city', 'claim-bg-yy-world', 'claim-bg-yy-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-yy-scene', 'claim-bg-yy-city', 'claim-bg-yy-world', 'claim-bg-yy-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-yy-scene', 'bg-yy-city', 'bg-yy-world', 'bg-yy-person');
DELETE FROM poetry_background WHERE id IN ('bg-yy-scene', 'bg-yy-city', 'bg-yy-world', 'bg-yy-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-yy-scene', 'claim-bg-yy-city', 'claim-bg-yy-world', 'claim-bg-yy-person');
DELETE FROM poetry_content WHERE id IN ('bg-yy-scene', 'bg-yy-city', 'bg-yy-world', 'bg-yy-person');
DELETE FROM poetry_source WHERE id IN ('source-quantangshi-233');
DELETE FROM poetry_schema_version WHERE version_no = 27;
COMMIT;
