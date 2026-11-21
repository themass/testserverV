-- V074 精确回滚：只删 V074 插入的行（id 全枚举）。source 只删一行：
-- source-ws-t300-032 是本迁移新建的选本页源（恰一枚，审计断言）——按 id 删除；
-- source-quantangshi-540 是 V018 已立的卷540 卷页源（本迁移复用），绝不删；
-- work-t300-032 本体、其 text_line 8 行都是 V018 的行，绝不删；
-- source-zizhi-tongjian-events / source-jiutangshu-wenyuan 为他迁移所立，零删除。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-032-scene', 'claim-bg-032-city', 'claim-bg-032-world', 'claim-bg-032-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-032-scene', 'claim-bg-032-city', 'claim-bg-032-world', 'claim-bg-032-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-032-scene', 'bg-032-city', 'bg-032-world', 'bg-032-person');
DELETE FROM poetry_background WHERE id IN ('bg-032-scene', 'bg-032-city', 'bg-032-world', 'bg-032-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-032-scene', 'claim-bg-032-city', 'claim-bg-032-world', 'claim-bg-032-person');
DELETE FROM poetry_content WHERE id IN ('bg-032-scene', 'bg-032-city', 'bg-032-world', 'bg-032-person');
DELETE FROM poetry_source WHERE id = 'source-ws-t300-032';
DELETE FROM poetry_schema_version WHERE version_no = 74;
COMMIT;
