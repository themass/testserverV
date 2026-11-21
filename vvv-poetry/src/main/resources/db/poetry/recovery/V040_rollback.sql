-- V040 精确回滚：只删 V040 插入的行（id 全枚举）。
-- work-t300-148 本体、其 text_line 4 行与 source-ws-t300-148 都是 V018 的行，绝不删；
-- 共用 source 行（jiutangshu-wenyuan/xintangshu-wenyi/quantangshi-128/tongjian）与 V026 的行不删；
-- V040 零新 source、零 relation。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-99-scene', 'claim-bg-99-city', 'claim-bg-99-world', 'claim-bg-99-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-99-scene', 'claim-bg-99-city', 'claim-bg-99-world', 'claim-bg-99-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-99-scene', 'bg-99-city', 'bg-99-world', 'bg-99-person');
DELETE FROM poetry_background WHERE id IN ('bg-99-scene', 'bg-99-city', 'bg-99-world', 'bg-99-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-99-scene', 'claim-bg-99-city', 'claim-bg-99-world', 'claim-bg-99-person');
DELETE FROM poetry_content WHERE id IN ('bg-99-scene', 'bg-99-city', 'bg-99-world', 'bg-99-person');
DELETE FROM poetry_schema_version WHERE version_no = 40;
COMMIT;
