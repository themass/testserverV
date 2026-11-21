-- V051 精确回滚：只删 V051 插入的行（id 全枚举），含本迁移新立的 source-quantangshi-159。
-- work-t300-108 本体、其 text_line 10 行与 source-ws-t300-108 都是 V018 的行，绝不删；
-- 其余共用 source 行（xintangshu-wenyi/quantangshi-160/zizhi-tongjian-events）与既往迁移的行不删；
-- V051 零 relation。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-108-scene', 'claim-bg-108-city', 'claim-bg-108-world', 'claim-bg-108-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-108-scene', 'claim-bg-108-city', 'claim-bg-108-world', 'claim-bg-108-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-108-scene', 'bg-108-city', 'bg-108-world', 'bg-108-person');
DELETE FROM poetry_background WHERE id IN ('bg-108-scene', 'bg-108-city', 'bg-108-world', 'bg-108-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-108-scene', 'claim-bg-108-city', 'claim-bg-108-world', 'claim-bg-108-person');
DELETE FROM poetry_content WHERE id IN ('bg-108-scene', 'bg-108-city', 'bg-108-world', 'bg-108-person');
DELETE FROM poetry_source WHERE id IN ('source-quantangshi-159');
DELETE FROM poetry_schema_version WHERE version_no = 51;
COMMIT;
