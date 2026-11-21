-- V038 精确回滚：只删 V038 插入的行（id 全枚举）。
-- work-t300-122 本体、其 text_line 4 行与 source-ws-t300-122 都是 V018 的行，绝不删；
-- 共用 source 行（jiutangshu-wenyuan/xintangshu-wenyi）与 V031 的行不删；
-- V038 零新 source、零 relation。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-jd-scene', 'claim-bg-jd-city', 'claim-bg-jd-world', 'claim-bg-jd-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-jd-scene', 'claim-bg-jd-city', 'claim-bg-jd-world', 'claim-bg-jd-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-jd-scene', 'bg-jd-city', 'bg-jd-world', 'bg-jd-person');
DELETE FROM poetry_background WHERE id IN ('bg-jd-scene', 'bg-jd-city', 'bg-jd-world', 'bg-jd-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-jd-scene', 'claim-bg-jd-city', 'claim-bg-jd-world', 'claim-bg-jd-person');
DELETE FROM poetry_content WHERE id IN ('bg-jd-scene', 'bg-jd-city', 'bg-jd-world', 'bg-jd-person');
DELETE FROM poetry_schema_version WHERE version_no = 38;
COMMIT;
