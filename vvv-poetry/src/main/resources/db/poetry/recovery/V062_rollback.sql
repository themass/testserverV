-- V062 精确回滚：只删 V062 插入的行（id 全枚举）。零 source 删除：
-- source-quantangshi-126 是 V035/V039/V052/V054/V060 已立的卷126 源行（本迁移第六次复用），绝不删；
-- work-t300-063 本体、其 text_line 8 行与 source-ws-t300-063 都是 V018 的行，绝不删；
-- source-xintangshu-wenyi/zizhi-tongjian-events 均为他迁移所立，零删除；V062 零 relation。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-063-scene', 'claim-bg-063-city', 'claim-bg-063-world', 'claim-bg-063-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-063-scene', 'claim-bg-063-city', 'claim-bg-063-world', 'claim-bg-063-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-063-scene', 'bg-063-city', 'bg-063-world', 'bg-063-person');
DELETE FROM poetry_background WHERE id IN ('bg-063-scene', 'bg-063-city', 'bg-063-world', 'bg-063-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-063-scene', 'claim-bg-063-city', 'claim-bg-063-world', 'claim-bg-063-person');
DELETE FROM poetry_content WHERE id IN ('bg-063-scene', 'bg-063-city', 'bg-063-world', 'bg-063-person');
DELETE FROM poetry_schema_version WHERE version_no = 62;
COMMIT;
