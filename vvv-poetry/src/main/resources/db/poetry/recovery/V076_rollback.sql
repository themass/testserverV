-- V076 精确回滚：只删 V076 插入的行（id 全枚举）。**source 只删一行**——
-- source-quantangshi-253 是本迁移新建的卷页源（恰一枚，审计断言），按 id 删除；
-- source-ws-t300-361 是 V018 所立的选本页源、source-quantangshi-283 是 V033 所立的卷283 源（本迁移复用），绝不删；
-- work-t300-361 本体与其 text_line 4 行都是 V018 的行，绝不删；
-- source-zizhi-tongjian-events 为他迁移所立，零删除。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-361-scene', 'claim-bg-361-city', 'claim-bg-361-world', 'claim-bg-361-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-361-scene', 'claim-bg-361-city', 'claim-bg-361-world', 'claim-bg-361-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-361-scene', 'bg-361-city', 'bg-361-world', 'bg-361-person');
DELETE FROM poetry_background WHERE id IN ('bg-361-scene', 'bg-361-city', 'bg-361-world', 'bg-361-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-361-scene', 'claim-bg-361-city', 'claim-bg-361-world', 'claim-bg-361-person');
DELETE FROM poetry_content WHERE id IN ('bg-361-scene', 'bg-361-city', 'bg-361-world', 'bg-361-person');
DELETE FROM poetry_source WHERE id = 'source-quantangshi-253';
DELETE FROM poetry_schema_version WHERE version_no = 76;
COMMIT;
