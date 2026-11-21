-- V065 精确回滚：只删 V065 插入的行（id 全枚举）。零 source 删除：
-- source-quantangshi-125 是 V037/V055/V057/V064 已立的卷125 源行（本迁移第五次复用），绝不删；
-- work-t300-061 本体、其 text_line 20 行与 source-ws-t300-061 都是 V018 的行，绝不删；
-- source-xintangshu-wenyi / source-zizhi-tongjian-events 为他迁移所立，零删除。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-061-scene', 'claim-bg-061-city', 'claim-bg-061-world', 'claim-bg-061-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-061-scene', 'claim-bg-061-city', 'claim-bg-061-world', 'claim-bg-061-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-061-scene', 'bg-061-city', 'bg-061-world', 'bg-061-person');
DELETE FROM poetry_background WHERE id IN ('bg-061-scene', 'bg-061-city', 'bg-061-world', 'bg-061-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-061-scene', 'claim-bg-061-city', 'claim-bg-061-world', 'claim-bg-061-person');
DELETE FROM poetry_content WHERE id IN ('bg-061-scene', 'bg-061-city', 'bg-061-world', 'bg-061-person');
DELETE FROM poetry_schema_version WHERE version_no = 65;
COMMIT;
