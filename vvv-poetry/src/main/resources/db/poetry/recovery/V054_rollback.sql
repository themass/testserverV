-- V054 精确回滚：只删 V054 插入的行（id 全枚举）。
-- work-t300-137 本体、其 text_line 8 行与 source-ws-t300-137 都是 V018 的行，绝不删；
-- 全部四个共用 source 行（ws-137/quantangshi-126/jiutangshu-wenyuan/
-- zizhi-tongjian-events）均为他迁移所立，零删除（本迁移零新 source）；V054 零 relation。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-137-scene', 'claim-bg-137-city', 'claim-bg-137-world', 'claim-bg-137-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-137-scene', 'claim-bg-137-city', 'claim-bg-137-world', 'claim-bg-137-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-137-scene', 'bg-137-city', 'bg-137-world', 'bg-137-person');
DELETE FROM poetry_background WHERE id IN ('bg-137-scene', 'bg-137-city', 'bg-137-world', 'bg-137-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-137-scene', 'claim-bg-137-city', 'claim-bg-137-world', 'claim-bg-137-person');
DELETE FROM poetry_content WHERE id IN ('bg-137-scene', 'bg-137-city', 'bg-137-world', 'bg-137-person');
DELETE FROM poetry_schema_version WHERE version_no = 54;
COMMIT;
