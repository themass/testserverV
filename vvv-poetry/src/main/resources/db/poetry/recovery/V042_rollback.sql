-- V042 精确回滚：只删 V042 插入的行（id 全枚举）。
-- work-t300-312 本体、其 text_line 6 行与 source-ws-t300-312 都是 V018 的行，绝不删；
-- 共用 source 行（xintangshu-wenyi/tongjian）不删；V042 自开的 source-quantangshi-165 删除。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-cs-scene', 'claim-bg-cs-city', 'claim-bg-cs-world', 'claim-bg-cs-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-cs-scene', 'claim-bg-cs-city', 'claim-bg-cs-world', 'claim-bg-cs-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-cs-scene', 'bg-cs-city', 'bg-cs-world', 'bg-cs-person');
DELETE FROM poetry_background WHERE id IN ('bg-cs-scene', 'bg-cs-city', 'bg-cs-world', 'bg-cs-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-cs-scene', 'claim-bg-cs-city', 'claim-bg-cs-world', 'claim-bg-cs-person');
DELETE FROM poetry_content WHERE id IN ('bg-cs-scene', 'bg-cs-city', 'bg-cs-world', 'bg-cs-person');
DELETE FROM poetry_source WHERE id IN ('source-quantangshi-165');
DELETE FROM poetry_schema_version WHERE version_no = 42;
COMMIT;
