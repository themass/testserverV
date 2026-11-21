-- V041 精确回滚：只删 V041 插入的行（id 全枚举）。
-- work-t300-323 本体、其 text_line 8 行与 source-ws-t300-323 都是 V018 的行，绝不删；
-- 共用 source 行（jiutangshu-wenyuan/xintangshu-wenyi）与 V032/V036 的行不删；
-- V041 零新 source、零 relation。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-fr-scene', 'claim-bg-fr-city', 'claim-bg-fr-world', 'claim-bg-fr-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-fr-scene', 'claim-bg-fr-city', 'claim-bg-fr-world', 'claim-bg-fr-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-fr-scene', 'bg-fr-city', 'bg-fr-world', 'bg-fr-person');
DELETE FROM poetry_background WHERE id IN ('bg-fr-scene', 'bg-fr-city', 'bg-fr-world', 'bg-fr-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-fr-scene', 'claim-bg-fr-city', 'claim-bg-fr-world', 'claim-bg-fr-person');
DELETE FROM poetry_content WHERE id IN ('bg-fr-scene', 'bg-fr-city', 'bg-fr-world', 'bg-fr-person');
DELETE FROM poetry_schema_version WHERE version_no = 41;
COMMIT;
