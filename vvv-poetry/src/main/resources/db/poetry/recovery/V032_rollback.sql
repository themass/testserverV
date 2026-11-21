-- V032 精确回滚：只删 V032 插入的行（id 全枚举）。
-- work-t300-326 本体、其 text_line 8 行与 source-ws-t300-326 都是 V018 的行，绝不删；
-- 共用 source 行（jiutangshu-wenyuan/xintangshu-wenyi）不删；V032 零 poetry_relation 行。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-jl-scene', 'claim-bg-jl-city', 'claim-bg-jl-world', 'claim-bg-jl-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-jl-scene', 'claim-bg-jl-city', 'claim-bg-jl-world', 'claim-bg-jl-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-jl-scene', 'bg-jl-city', 'bg-jl-world', 'bg-jl-person');
DELETE FROM poetry_background WHERE id IN ('bg-jl-scene', 'bg-jl-city', 'bg-jl-world', 'bg-jl-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-jl-scene', 'claim-bg-jl-city', 'claim-bg-jl-world', 'claim-bg-jl-person');
DELETE FROM poetry_content WHERE id IN ('bg-jl-scene', 'bg-jl-city', 'bg-jl-world', 'bg-jl-person');
DELETE FROM poetry_schema_version WHERE version_no = 32;
COMMIT;
