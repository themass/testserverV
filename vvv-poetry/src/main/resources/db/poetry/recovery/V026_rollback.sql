-- V026 精确回滚：只删 V026 插入的行（id 全枚举）。work-t300-140 本体是 V018 的行，绝不删；
-- 共用 source 行（dushi-xiangzhu-05=V025、两唐书文苑/V016、通鉴/V015）都不删。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-wd-scene', 'claim-bg-wd-city', 'claim-bg-wd-world', 'claim-bg-wd-person', 'claim-wd-time-758', 'claim-wd-in-anshi');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-wd-scene', 'claim-bg-wd-city', 'claim-bg-wd-world', 'claim-bg-wd-person', 'claim-wd-time-758', 'claim-wd-in-anshi');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-wd-scene', 'bg-wd-city', 'bg-wd-world', 'bg-wd-person');
DELETE FROM poetry_background WHERE id IN ('bg-wd-scene', 'bg-wd-city', 'bg-wd-world', 'bg-wd-person');
DELETE FROM poetry_relation WHERE id IN ('rel-work-t300-140-written-during-anshi');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-wd-scene', 'claim-bg-wd-city', 'claim-bg-wd-world', 'claim-bg-wd-person', 'claim-wd-time-758', 'claim-wd-in-anshi');
DELETE FROM poetry_content WHERE id IN ('bg-wd-scene', 'bg-wd-city', 'bg-wd-world', 'bg-wd-person');
DELETE FROM poetry_source WHERE id IN ('source-quantangshi-128');
DELETE FROM poetry_schema_version WHERE version_no = 26;
COMMIT;
