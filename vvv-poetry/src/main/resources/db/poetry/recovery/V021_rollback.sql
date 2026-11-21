-- V021 精确回滚：只删 V021 插入的行（id 全枚举）。work-t300-209 本体是 V018 的行，绝不删。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-chunsu-scene', 'claim-bg-chunsu-city', 'claim-bg-chunsu-world', 'claim-bg-chunsu-person', 'claim-chun-su-time-757', 'claim-chun-su-in-anshi');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-chunsu-scene', 'claim-bg-chunsu-city', 'claim-bg-chunsu-world', 'claim-bg-chunsu-person', 'claim-chun-su-time-757', 'claim-chun-su-in-anshi');
DELETE FROM poetry_relation WHERE id IN ('rel-work-t300-209-written-during-anshi');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-chunsu-scene', 'bg-chunsu-city', 'bg-chunsu-world', 'bg-chunsu-person');
DELETE FROM poetry_background WHERE id IN ('bg-chunsu-scene', 'bg-chunsu-city', 'bg-chunsu-world', 'bg-chunsu-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-chunsu-scene', 'claim-bg-chunsu-city', 'claim-bg-chunsu-world', 'claim-bg-chunsu-person', 'claim-chun-su-time-757', 'claim-chun-su-in-anshi');
DELETE FROM poetry_content WHERE id IN ('bg-chunsu-scene', 'bg-chunsu-city', 'bg-chunsu-world', 'bg-chunsu-person');
DELETE FROM poetry_schema_version WHERE version_no = 21;
COMMIT;
