-- V060 精确回滚：只删 V060 插入的行（id 全枚举）。零 source 删除：
-- source-quantangshi-126 是 V035/V039/V052/V054 已立的卷126 源行（本迁移第五次复用），绝不删；
-- work-t300-136 本体、其 text_line 8 行与 source-ws-t300-136 都是 V018 的行，绝不删；
-- source-jiutangshu-wenyuan/source-xintangshu-wenyi/zizhi-tongjian-events 均为他迁移所立，
-- 零删除；V060 零 relation。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-136-scene', 'claim-bg-136-city', 'claim-bg-136-world', 'claim-bg-136-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-136-scene', 'claim-bg-136-city', 'claim-bg-136-world', 'claim-bg-136-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-136-scene', 'bg-136-city', 'bg-136-world', 'bg-136-person');
DELETE FROM poetry_background WHERE id IN ('bg-136-scene', 'bg-136-city', 'bg-136-world', 'bg-136-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-136-scene', 'claim-bg-136-city', 'claim-bg-136-world', 'claim-bg-136-person');
DELETE FROM poetry_content WHERE id IN ('bg-136-scene', 'bg-136-city', 'bg-136-world', 'bg-136-person');
DELETE FROM poetry_schema_version WHERE version_no = 60;
COMMIT;
