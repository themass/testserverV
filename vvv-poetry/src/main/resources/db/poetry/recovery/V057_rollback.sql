-- V057 精确回滚：只删 V057 插入的行（id 全枚举）。
-- work-t300-056 本体、其 text_line 12 行与 source-ws-t300-056 都是 V018 的行，绝不删；
-- 全部五个共用 source 行（ws-056/quantangshi-125/jiutangshu-wenyuan/xintangshu-wenyi/
-- zizhi-tongjian-events）均为他迁移所立，零删除（本迁移零新 source）；V057 零 relation。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-056-scene', 'claim-bg-056-city', 'claim-bg-056-world', 'claim-bg-056-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-056-scene', 'claim-bg-056-city', 'claim-bg-056-world', 'claim-bg-056-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-056-scene', 'bg-056-city', 'bg-056-world', 'bg-056-person');
DELETE FROM poetry_background WHERE id IN ('bg-056-scene', 'bg-056-city', 'bg-056-world', 'bg-056-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-056-scene', 'claim-bg-056-city', 'claim-bg-056-world', 'claim-bg-056-person');
DELETE FROM poetry_content WHERE id IN ('bg-056-scene', 'bg-056-city', 'bg-056-world', 'bg-056-person');
DELETE FROM poetry_schema_version WHERE version_no = 57;
COMMIT;
