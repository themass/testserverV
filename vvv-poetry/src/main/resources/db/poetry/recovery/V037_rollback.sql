-- V037 精确回滚：只删 V037 插入的行（id 全枚举）。
-- work-t300-054 本体、其 text_line 6 行与 source-ws-t300-054 都是 V018 的行，绝不删；
-- 共用 source 行（jiutangshu-wenyuan/xintangshu-wenyi）不删；
-- V037 自开的 source-quantangshi-125 随回滚删除；零 relation。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-sb-scene', 'claim-bg-sb-city', 'claim-bg-sb-world', 'claim-bg-sb-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-sb-scene', 'claim-bg-sb-city', 'claim-bg-sb-world', 'claim-bg-sb-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-sb-scene', 'bg-sb-city', 'bg-sb-world', 'bg-sb-person');
DELETE FROM poetry_background WHERE id IN ('bg-sb-scene', 'bg-sb-city', 'bg-sb-world', 'bg-sb-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-sb-scene', 'claim-bg-sb-city', 'claim-bg-sb-world', 'claim-bg-sb-person');
DELETE FROM poetry_content WHERE id IN ('bg-sb-scene', 'bg-sb-city', 'bg-sb-world', 'bg-sb-person');
DELETE FROM poetry_source WHERE id IN ('source-quantangshi-125');
DELETE FROM poetry_schema_version WHERE version_no = 37;
COMMIT;
