-- V044 精确回滚：只删 V044 插入的行（id 全枚举）。
-- work-t300-142 本体、其 text_line 8 行与 source-ws-t300-142 都是 V018 的行，绝不删；
-- 共用 source 行（jiutangshu-wenyuan/xintangshu-wenyi）与 V035/V037/V039/V043 的行不删；
-- V044 零新 source、零 relation。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-jy-scene', 'claim-bg-jy-city', 'claim-bg-jy-world', 'claim-bg-jy-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-jy-scene', 'claim-bg-jy-city', 'claim-bg-jy-world', 'claim-bg-jy-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-jy-scene', 'bg-jy-city', 'bg-jy-world', 'bg-jy-person');
DELETE FROM poetry_background WHERE id IN ('bg-jy-scene', 'bg-jy-city', 'bg-jy-world', 'bg-jy-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-jy-scene', 'claim-bg-jy-city', 'claim-bg-jy-world', 'claim-bg-jy-person');
DELETE FROM poetry_content WHERE id IN ('bg-jy-scene', 'bg-jy-city', 'bg-jy-world', 'bg-jy-person');
DELETE FROM poetry_schema_version WHERE version_no = 44;
COMMIT;
