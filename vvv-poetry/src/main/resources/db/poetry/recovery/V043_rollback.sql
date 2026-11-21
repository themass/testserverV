-- V043 精确回滚：只删 V043 插入的行（id 全枚举）。
-- work-t300-134 本体、其 text_line 8 行与 source-ws-t300-134 都是 V018 的行，绝不删；
-- 共用 source 行（jiutangshu-wenyuan/xintangshu-wenyi）与 V035/V039 的行不删；
-- V043 零新 source、零 relation。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-sq-scene', 'claim-bg-sq-city', 'claim-bg-sq-world', 'claim-bg-sq-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-sq-scene', 'claim-bg-sq-city', 'claim-bg-sq-world', 'claim-bg-sq-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-sq-scene', 'bg-sq-city', 'bg-sq-world', 'bg-sq-person');
DELETE FROM poetry_background WHERE id IN ('bg-sq-scene', 'bg-sq-city', 'bg-sq-world', 'bg-sq-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-sq-scene', 'claim-bg-sq-city', 'claim-bg-sq-world', 'claim-bg-sq-person');
DELETE FROM poetry_content WHERE id IN ('bg-sq-scene', 'bg-sq-city', 'bg-sq-world', 'bg-sq-person');
DELETE FROM poetry_schema_version WHERE version_no = 43;
COMMIT;
