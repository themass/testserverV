-- V046 精确回滚：只删 V046 插入的行（id 全枚举）。
-- work-t300-328 本体、其 text_line 8 行与 source-ws-t300-328 都是 V018 的行，绝不删；
-- 共用 source 行（jiutangshu-wenyuan/xintangshu-wenyi）与 V032/V036/V045 的行不删；
-- V046 零新 source、零 relation。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-nz-scene', 'claim-bg-nz-city', 'claim-bg-nz-world', 'claim-bg-nz-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-nz-scene', 'claim-bg-nz-city', 'claim-bg-nz-world', 'claim-bg-nz-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-nz-scene', 'bg-nz-city', 'bg-nz-world', 'bg-nz-person');
DELETE FROM poetry_background WHERE id IN ('bg-nz-scene', 'bg-nz-city', 'bg-nz-world', 'bg-nz-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-nz-scene', 'claim-bg-nz-city', 'claim-bg-nz-world', 'claim-bg-nz-person');
DELETE FROM poetry_content WHERE id IN ('bg-nz-scene', 'bg-nz-city', 'bg-nz-world', 'bg-nz-person');
DELETE FROM poetry_schema_version WHERE version_no = 46;
COMMIT;
