-- V024 精确回滚：只删 V024 插入的行（id 全枚举）。work-t300-220 本体是 V018 的行，绝不删。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-dl-scene', 'claim-bg-dl-city', 'claim-bg-dl-world', 'claim-bg-dl-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-dl-scene', 'claim-bg-dl-city', 'claim-bg-dl-world', 'claim-bg-dl-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-dl-scene', 'bg-dl-city', 'bg-dl-world', 'bg-dl-person');
DELETE FROM poetry_background WHERE id IN ('bg-dl-scene', 'bg-dl-city', 'bg-dl-world', 'bg-dl-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-dl-scene', 'claim-bg-dl-city', 'claim-bg-dl-world', 'claim-bg-dl-person');
DELETE FROM poetry_content WHERE id IN ('bg-dl-scene', 'bg-dl-city', 'bg-dl-world', 'bg-dl-person');
DELETE FROM poetry_schema_version WHERE version_no = 24;
COMMIT;
