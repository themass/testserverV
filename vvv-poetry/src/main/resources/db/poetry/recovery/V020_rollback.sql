-- V020 精确回滚：只删 V020 插入的行（id 全枚举）。
-- 注意：poetry_content 只删 4 个 bg-yueye-* 行；work-t300-207 本体是 V018 的行，绝不碰。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-yueye-scene', 'claim-bg-yueye-city', 'claim-bg-yueye-world', 'claim-bg-yueye-person', 'claim-yueye-time-756', 'claim-yueye-in-anshi');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-yueye-scene', 'claim-bg-yueye-city', 'claim-bg-yueye-world', 'claim-bg-yueye-person', 'claim-yueye-time-756', 'claim-yueye-in-anshi');
DELETE FROM poetry_relation WHERE id IN ('rel-work-t300-207-written-during-anshi');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-yueye-scene', 'bg-yueye-city', 'bg-yueye-world', 'bg-yueye-person');
DELETE FROM poetry_background WHERE id IN ('bg-yueye-scene', 'bg-yueye-city', 'bg-yueye-world', 'bg-yueye-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-yueye-scene', 'claim-bg-yueye-city', 'claim-bg-yueye-world', 'claim-bg-yueye-person', 'claim-yueye-time-756', 'claim-yueye-in-anshi');
DELETE FROM poetry_content WHERE id IN ('bg-yueye-scene', 'bg-yueye-city', 'bg-yueye-world', 'bg-yueye-person');
DELETE FROM poetry_schema_version WHERE version_no = 20;
COMMIT;
