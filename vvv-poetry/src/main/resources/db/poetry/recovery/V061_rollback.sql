-- V061 精确回滚：只删 V061 插入的行（id 全枚举）。零 source 删除：
-- source-quantangshi-128 是 V026/V040 已立的卷128 源行（本迁移第六次复用），绝不删；
-- work-t300-145 本体、其 text_line 4 行与 source-ws-t300-145 都是 V018 的行，绝不删；
-- source-xintangshu-wenyi/zizhi-tongjian-events 均为他迁移所立，零删除；V061 零 relation。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-145-scene', 'claim-bg-145-city', 'claim-bg-145-world', 'claim-bg-145-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-145-scene', 'claim-bg-145-city', 'claim-bg-145-world', 'claim-bg-145-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-145-scene', 'bg-145-city', 'bg-145-world', 'bg-145-person');
DELETE FROM poetry_background WHERE id IN ('bg-145-scene', 'bg-145-city', 'bg-145-world', 'bg-145-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-145-scene', 'claim-bg-145-city', 'claim-bg-145-world', 'claim-bg-145-person');
DELETE FROM poetry_content WHERE id IN ('bg-145-scene', 'bg-145-city', 'bg-145-world', 'bg-145-person');
DELETE FROM poetry_schema_version WHERE version_no = 61;
COMMIT;
