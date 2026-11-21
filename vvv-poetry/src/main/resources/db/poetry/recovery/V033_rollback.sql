-- V033 精确回滚：只删 V033 插入的行（id 全枚举）。
-- work-t300-087 本体、其 text_line 8 行与 source-ws-t300-087 都是 V018 的行，绝不删；
-- 共用 source 行（xintangshu-wenyi/tongjian-events）不删；V033 零 poetry_relation 行。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-xy-scene', 'claim-bg-xy-city', 'claim-bg-xy-world', 'claim-bg-xy-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-xy-scene', 'claim-bg-xy-city', 'claim-bg-xy-world', 'claim-bg-xy-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-xy-scene', 'bg-xy-city', 'bg-xy-world', 'bg-xy-person');
DELETE FROM poetry_background WHERE id IN ('bg-xy-scene', 'bg-xy-city', 'bg-xy-world', 'bg-xy-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-xy-scene', 'claim-bg-xy-city', 'claim-bg-xy-world', 'claim-bg-xy-person');
DELETE FROM poetry_content WHERE id IN ('bg-xy-scene', 'bg-xy-city', 'bg-xy-world', 'bg-xy-person');
DELETE FROM poetry_source WHERE id IN ('source-quantangshi-283');
DELETE FROM poetry_schema_version WHERE version_no = 33;
COMMIT;
