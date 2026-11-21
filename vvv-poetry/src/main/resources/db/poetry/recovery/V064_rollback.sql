-- V064 精确回滚：只删 V064 插入的行（id 全枚举）。零 source 删除：
-- source-quantangshi-125 是 V037/V055/V057 已立的卷125 源行（本迁移第四次复用），绝不删；
-- work-t300-060 本体、其 text_line 32 行与 source-ws-t300-060 都是 V018 的行，绝不删；
-- source-zizhi-tongjian-events 为他迁移所立，零删除；V064 零 relation、PERSON 零首引。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-060-scene', 'claim-bg-060-city', 'claim-bg-060-world', 'claim-bg-060-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-060-scene', 'claim-bg-060-city', 'claim-bg-060-world', 'claim-bg-060-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-060-scene', 'bg-060-city', 'bg-060-world', 'bg-060-person');
DELETE FROM poetry_background WHERE id IN ('bg-060-scene', 'bg-060-city', 'bg-060-world', 'bg-060-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-060-scene', 'claim-bg-060-city', 'claim-bg-060-world', 'claim-bg-060-person');
DELETE FROM poetry_content WHERE id IN ('bg-060-scene', 'bg-060-city', 'bg-060-world', 'bg-060-person');
DELETE FROM poetry_schema_version WHERE version_no = 64;
COMMIT;
