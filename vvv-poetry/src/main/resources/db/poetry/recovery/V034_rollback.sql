-- V034 精确回滚：只删 V034 插入的行（id 全枚举）。
-- work-t300-106 本体、其 text_line 4 行与 source-ws-t300-106 都是 V018 的行，绝不删；
-- 共用 source 行（jiutangshu-wenyuan/xintangshu-wenyi/tongjian-events）不删；V034 零新 source、零 relation。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-lz-scene', 'claim-bg-lz-city', 'claim-bg-lz-world', 'claim-bg-lz-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-lz-scene', 'claim-bg-lz-city', 'claim-bg-lz-world', 'claim-bg-lz-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-lz-scene', 'bg-lz-city', 'bg-lz-world', 'bg-lz-person');
DELETE FROM poetry_background WHERE id IN ('bg-lz-scene', 'bg-lz-city', 'bg-lz-world', 'bg-lz-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-lz-scene', 'claim-bg-lz-city', 'claim-bg-lz-world', 'claim-bg-lz-person');
DELETE FROM poetry_content WHERE id IN ('bg-lz-scene', 'bg-lz-city', 'bg-lz-world', 'bg-lz-person');
DELETE FROM poetry_schema_version WHERE version_no = 34;
COMMIT;
