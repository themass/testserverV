-- V039 精确回滚：只删 V039 插入的行（id 全枚举）。
-- work-t300-135 本体、其 text_line 8 行与 source-ws-t300-135 都是 V018 的行，绝不删；
-- 共用 source 行（jiutangshu-wenyuan/xintangshu-wenyi/quantangshi-126）与 V035 的行不删；
-- V039 零新 source、零 relation。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-zn-scene', 'claim-bg-zn-city', 'claim-bg-zn-world', 'claim-bg-zn-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-zn-scene', 'claim-bg-zn-city', 'claim-bg-zn-world', 'claim-bg-zn-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-zn-scene', 'bg-zn-city', 'bg-zn-world', 'bg-zn-person');
DELETE FROM poetry_background WHERE id IN ('bg-zn-scene', 'bg-zn-city', 'bg-zn-world', 'bg-zn-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-zn-scene', 'claim-bg-zn-city', 'claim-bg-zn-world', 'claim-bg-zn-person');
DELETE FROM poetry_content WHERE id IN ('bg-zn-scene', 'bg-zn-city', 'bg-zn-world', 'bg-zn-person');
DELETE FROM poetry_schema_version WHERE version_no = 39;
COMMIT;
