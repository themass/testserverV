-- V045 精确回滚：只删 V045 插入的行（id 全枚举）。
-- work-t300-320 本体、其 text_line 6 行与 source-ws-t300-320 都是 V018 的行，绝不删；
-- 共用 source 行（jiutangshu-wenyuan/xintangshu-wenyi）与 V032/V036/V041 的行不删；
-- V045 零新 source、零 relation。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-lb-scene', 'claim-bg-lb-city', 'claim-bg-lb-world', 'claim-bg-lb-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-lb-scene', 'claim-bg-lb-city', 'claim-bg-lb-world', 'claim-bg-lb-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-lb-scene', 'bg-lb-city', 'bg-lb-world', 'bg-lb-person');
DELETE FROM poetry_background WHERE id IN ('bg-lb-scene', 'bg-lb-city', 'bg-lb-world', 'bg-lb-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-lb-scene', 'claim-bg-lb-city', 'claim-bg-lb-world', 'claim-bg-lb-person');
DELETE FROM poetry_content WHERE id IN ('bg-lb-scene', 'bg-lb-city', 'bg-lb-world', 'bg-lb-person');
DELETE FROM poetry_schema_version WHERE version_no = 45;
COMMIT;
