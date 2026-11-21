-- V031 精确回滚：只删 V031 插入的行（id 全枚举）。
-- work-t300-119 本体、其 text_line 8 行与 source-ws-t300-119 都是 V018 的行，绝不删；
-- 共用 source 行（jiutangshu-wenyuan/xintangshu-wenyi）不删；V031 零 poetry_relation 行。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-sm-scene', 'claim-bg-sm-city', 'claim-bg-sm-world', 'claim-bg-sm-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-sm-scene', 'claim-bg-sm-city', 'claim-bg-sm-world', 'claim-bg-sm-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-sm-scene', 'bg-sm-city', 'bg-sm-world', 'bg-sm-person');
DELETE FROM poetry_background WHERE id IN ('bg-sm-scene', 'bg-sm-city', 'bg-sm-world', 'bg-sm-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-sm-scene', 'claim-bg-sm-city', 'claim-bg-sm-world', 'claim-bg-sm-person');
DELETE FROM poetry_content WHERE id IN ('bg-sm-scene', 'bg-sm-city', 'bg-sm-world', 'bg-sm-person');
DELETE FROM poetry_source WHERE id IN ('source-quantangshi-160');
DELETE FROM poetry_schema_version WHERE version_no = 31;
COMMIT;
