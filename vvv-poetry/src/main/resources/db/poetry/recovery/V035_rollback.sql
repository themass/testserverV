-- V035 精确回滚：只删 V035 插入的行（id 全枚举）。
-- work-t300-062 本体、其 text_line 8 行与 source-ws-t300-062 都是 V018 的行，绝不删；
-- 共用 source 行（jiutangshu-wenyuan/xintangshu-wenyi/tongjian-events）不删；
-- V035 自开的 source-quantangshi-126 随回滚删除；零 relation。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-wc-scene', 'claim-bg-wc-city', 'claim-bg-wc-world', 'claim-bg-wc-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-wc-scene', 'claim-bg-wc-city', 'claim-bg-wc-world', 'claim-bg-wc-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-wc-scene', 'bg-wc-city', 'bg-wc-world', 'bg-wc-person');
DELETE FROM poetry_background WHERE id IN ('bg-wc-scene', 'bg-wc-city', 'bg-wc-world', 'bg-wc-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-wc-scene', 'claim-bg-wc-city', 'claim-bg-wc-world', 'claim-bg-wc-person');
DELETE FROM poetry_content WHERE id IN ('bg-wc-scene', 'bg-wc-city', 'bg-wc-world', 'bg-wc-person');
DELETE FROM poetry_source WHERE id IN ('source-quantangshi-126');
DELETE FROM poetry_schema_version WHERE version_no = 35;
COMMIT;
