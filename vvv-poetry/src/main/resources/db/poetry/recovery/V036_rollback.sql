-- V036 精确回滚：只删 V036 插入的行（id 全枚举）。
-- work-t300-308 本体、其 text_line 4 行与 source-ws-t300-308 都是 V018 的行，绝不删；
-- 共用 source 行（jiutangshu-wenyuan/xintangshu-wenyi）不删；
-- V036 自开的 source-quantangshi-164 随回滚删除；零 relation。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-yj-scene', 'claim-bg-yj-city', 'claim-bg-yj-world', 'claim-bg-yj-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-yj-scene', 'claim-bg-yj-city', 'claim-bg-yj-world', 'claim-bg-yj-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-yj-scene', 'bg-yj-city', 'bg-yj-world', 'bg-yj-person');
DELETE FROM poetry_background WHERE id IN ('bg-yj-scene', 'bg-yj-city', 'bg-yj-world', 'bg-yj-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-yj-scene', 'claim-bg-yj-city', 'claim-bg-yj-world', 'claim-bg-yj-person');
DELETE FROM poetry_content WHERE id IN ('bg-yj-scene', 'bg-yj-city', 'bg-yj-world', 'bg-yj-person');
DELETE FROM poetry_source WHERE id IN ('source-quantangshi-164');
DELETE FROM poetry_schema_version WHERE version_no = 36;
COMMIT;
