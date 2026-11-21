-- V048 精确回滚：只删 V048 插入的行（id 全枚举）。
-- work-t300-118 本体、其 text_line 8 行与 source-ws-t300-118 都是 V018 的行，绝不删；
-- 共用 source 行（jiutangshu-wenyuan/xintangshu-wenyi/zizhi-tongjian-events）与既往迁移的行不删；
-- V048 零新 source、零 relation。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-118-scene', 'claim-bg-118-city', 'claim-bg-118-world', 'claim-bg-118-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-118-scene', 'claim-bg-118-city', 'claim-bg-118-world', 'claim-bg-118-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-118-scene', 'bg-118-city', 'bg-118-world', 'bg-118-person');
DELETE FROM poetry_background WHERE id IN ('bg-118-scene', 'bg-118-city', 'bg-118-world', 'bg-118-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-118-scene', 'claim-bg-118-city', 'claim-bg-118-world', 'claim-bg-118-person');
DELETE FROM poetry_content WHERE id IN ('bg-118-scene', 'bg-118-city', 'bg-118-world', 'bg-118-person');
DELETE FROM poetry_schema_version WHERE version_no = 48;
COMMIT;
