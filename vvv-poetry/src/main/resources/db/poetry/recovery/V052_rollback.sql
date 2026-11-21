-- V052 精确回滚：只删 V052 插入的行（id 全枚举）。
-- work-t300-133 本体、其 text_line 8 行与 source-ws-t300-133 都是 V018 的行，绝不删；
-- 全部六个共用 source 行（ws-133/quantangshi-126/quantangshi-227/jiutangshu-wenyuan/
-- xintangshu-wenyi/zizhi-tongjian-events）均为他迁移所立，零删除（本迁移零新 source）；
-- V052 零 relation。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-133-scene', 'claim-bg-133-city', 'claim-bg-133-world', 'claim-bg-133-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-133-scene', 'claim-bg-133-city', 'claim-bg-133-world', 'claim-bg-133-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-133-scene', 'bg-133-city', 'bg-133-world', 'bg-133-person');
DELETE FROM poetry_background WHERE id IN ('bg-133-scene', 'bg-133-city', 'bg-133-world', 'bg-133-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-133-scene', 'claim-bg-133-city', 'claim-bg-133-world', 'claim-bg-133-person');
DELETE FROM poetry_content WHERE id IN ('bg-133-scene', 'bg-133-city', 'bg-133-world', 'bg-133-person');
DELETE FROM poetry_schema_version WHERE version_no = 52;
COMMIT;
