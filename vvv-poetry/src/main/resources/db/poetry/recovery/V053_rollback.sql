-- V053 精确回滚：只删 V053 插入的行（id 全枚举）。
-- work-t300-121 本体、其 text_line 4 行与 source-ws-t300-121 都是 V018 的行，绝不删；
-- 全部六个共用 source 行（ws-121/quantangshi-160/283/301/jiutangshu-wenyuan/
-- xintangshu-wenyi）均为他迁移所立，零删除（本迁移零新 source）；V053 零 relation。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-121-scene', 'claim-bg-121-city', 'claim-bg-121-world', 'claim-bg-121-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-121-scene', 'claim-bg-121-city', 'claim-bg-121-world', 'claim-bg-121-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-121-scene', 'bg-121-city', 'bg-121-world', 'bg-121-person');
DELETE FROM poetry_background WHERE id IN ('bg-121-scene', 'bg-121-city', 'bg-121-world', 'bg-121-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-121-scene', 'claim-bg-121-city', 'claim-bg-121-world', 'claim-bg-121-person');
DELETE FROM poetry_content WHERE id IN ('bg-121-scene', 'bg-121-city', 'bg-121-world', 'bg-121-person');
DELETE FROM poetry_schema_version WHERE version_no = 53;
COMMIT;
