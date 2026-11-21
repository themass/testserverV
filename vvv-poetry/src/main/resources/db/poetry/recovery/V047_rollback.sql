-- V047 精确回滚：只删 V047 插入的行（id 全枚举）。
-- work-t300-325 本体、其 text_line 14 行与 source-ws-t300-325 都是 V018 的行，绝不删；
-- 共用 source 行（jiutangshu-wenyuan/xintangshu-wenyi/zizhi-tongjian-events）与既往迁移的行不删；
-- V047 零新 source、零 relation。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-325-scene', 'claim-bg-325-city', 'claim-bg-325-world', 'claim-bg-325-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-325-scene', 'claim-bg-325-city', 'claim-bg-325-world', 'claim-bg-325-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-325-scene', 'bg-325-city', 'bg-325-world', 'bg-325-person');
DELETE FROM poetry_background WHERE id IN ('bg-325-scene', 'bg-325-city', 'bg-325-world', 'bg-325-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-325-scene', 'claim-bg-325-city', 'claim-bg-325-world', 'claim-bg-325-person');
DELETE FROM poetry_content WHERE id IN ('bg-325-scene', 'bg-325-city', 'bg-325-world', 'bg-325-person');
DELETE FROM poetry_schema_version WHERE version_no = 47;
COMMIT;
