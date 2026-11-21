-- V022 精确回滚：只删 V022 插入的行（id 全枚举）。work-t300-217 本体是 V018 的行，绝不删。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-wgjs-scene', 'claim-bg-wgjs-city', 'claim-bg-wgjs-world', 'claim-bg-wgjs-person', 'claim-wgjs-time-763', 'claim-wgjs-in-anshi');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-wgjs-scene', 'claim-bg-wgjs-city', 'claim-bg-wgjs-world', 'claim-bg-wgjs-person', 'claim-wgjs-time-763', 'claim-wgjs-in-anshi');
DELETE FROM poetry_relation WHERE id IN ('rel-work-t300-217-written-during-anshi');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-wgjs-scene', 'bg-wgjs-city', 'bg-wgjs-world', 'bg-wgjs-person');
DELETE FROM poetry_background WHERE id IN ('bg-wgjs-scene', 'bg-wgjs-city', 'bg-wgjs-world', 'bg-wgjs-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-wgjs-scene', 'claim-bg-wgjs-city', 'claim-bg-wgjs-world', 'claim-bg-wgjs-person', 'claim-wgjs-time-763', 'claim-wgjs-in-anshi');
DELETE FROM poetry_content WHERE id IN ('bg-wgjs-scene', 'bg-wgjs-city', 'bg-wgjs-world', 'bg-wgjs-person');
DELETE FROM poetry_schema_version WHERE version_no = 22;
COMMIT;
