-- V063 精确回滚：只删 V063 插入的行（id 全枚举）。零 source 删除：
-- source-quantangshi-126 是 V035/V039/V052/V054/V060/V062 已立的卷126 源行（本迁移第七次复用），绝不删；
-- work-t300-064 本体、其 text_line 8 行与 source-ws-t300-064 都是 V018 的行，绝不删；
-- source-xintangshu-wenyi/zizhi-tongjian-events 均为他迁移所立，零删除；V063 零 relation。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-064-scene', 'claim-bg-064-city', 'claim-bg-064-world', 'claim-bg-064-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-064-scene', 'claim-bg-064-city', 'claim-bg-064-world', 'claim-bg-064-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-064-scene', 'bg-064-city', 'bg-064-world', 'bg-064-person');
DELETE FROM poetry_background WHERE id IN ('bg-064-scene', 'bg-064-city', 'bg-064-world', 'bg-064-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-064-scene', 'claim-bg-064-city', 'claim-bg-064-world', 'claim-bg-064-person');
DELETE FROM poetry_content WHERE id IN ('bg-064-scene', 'bg-064-city', 'bg-064-world', 'bg-064-person');
DELETE FROM poetry_schema_version WHERE version_no = 63;
COMMIT;
