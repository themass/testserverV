-- V055 精确回滚：只删 V055 插入的行（id 全枚举）。
-- work-t300-057 本体、其 text_line 10 行与 source-ws-t300-057 都是 V018 的行，绝不删；
-- 全部四个共用 source 行（ws-057/quantangshi-125/jiutangshu-wenyuan/
-- zizhi-tongjian-events）均为他迁移所立，零删除（本迁移零新 source）；V055 零 relation。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-057-scene', 'claim-bg-057-city', 'claim-bg-057-world', 'claim-bg-057-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-057-scene', 'claim-bg-057-city', 'claim-bg-057-world', 'claim-bg-057-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-057-scene', 'bg-057-city', 'bg-057-world', 'bg-057-person');
DELETE FROM poetry_background WHERE id IN ('bg-057-scene', 'bg-057-city', 'bg-057-world', 'bg-057-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-057-scene', 'claim-bg-057-city', 'claim-bg-057-world', 'claim-bg-057-person');
DELETE FROM poetry_content WHERE id IN ('bg-057-scene', 'bg-057-city', 'bg-057-world', 'bg-057-person');
DELETE FROM poetry_schema_version WHERE version_no = 55;
COMMIT;
