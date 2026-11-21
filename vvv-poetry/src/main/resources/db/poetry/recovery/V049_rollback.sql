-- V049 精确回滚：只删 V049 插入的行（id 全枚举）。
-- work-t300-112 本体、其 text_line 8 行与 source-ws-t300-112 都是 V018 的行，绝不删；
-- 共用 source 行（xintangshu-wenyi/quantangshi-160）与既往迁移的行不删；
-- V049 零新 source、零 relation。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-112-scene', 'claim-bg-112-city', 'claim-bg-112-world', 'claim-bg-112-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-112-scene', 'claim-bg-112-city', 'claim-bg-112-world', 'claim-bg-112-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-112-scene', 'bg-112-city', 'bg-112-world', 'bg-112-person');
DELETE FROM poetry_background WHERE id IN ('bg-112-scene', 'bg-112-city', 'bg-112-world', 'bg-112-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-112-scene', 'claim-bg-112-city', 'claim-bg-112-world', 'claim-bg-112-person');
DELETE FROM poetry_content WHERE id IN ('bg-112-scene', 'bg-112-city', 'bg-112-world', 'bg-112-person');
DELETE FROM poetry_schema_version WHERE version_no = 49;
COMMIT;
