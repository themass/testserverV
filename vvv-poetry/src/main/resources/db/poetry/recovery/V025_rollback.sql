-- V025 精确回滚：只删 V025 插入的行（id 全枚举）。work-t300-299 本体是 V018 的行，绝不删；
-- 共用通鉴来源行 source-zizhi-tongjian-events 是 V015 的行，本迁移只是增引卷220，不删。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-hz-scene', 'claim-bg-hz-city', 'claim-bg-hz-world', 'claim-bg-hz-person', 'claim-hz-time-758', 'claim-hz-in-anshi');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-hz-scene', 'claim-bg-hz-city', 'claim-bg-hz-world', 'claim-bg-hz-person', 'claim-hz-time-758', 'claim-hz-in-anshi');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-hz-scene', 'bg-hz-city', 'bg-hz-world', 'bg-hz-person');
DELETE FROM poetry_background WHERE id IN ('bg-hz-scene', 'bg-hz-city', 'bg-hz-world', 'bg-hz-person');
DELETE FROM poetry_relation WHERE id IN ('rel-work-t300-299-written-during-anshi');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-hz-scene', 'claim-bg-hz-city', 'claim-bg-hz-world', 'claim-bg-hz-person', 'claim-hz-time-758', 'claim-hz-in-anshi');
DELETE FROM poetry_content WHERE id IN ('bg-hz-scene', 'bg-hz-city', 'bg-hz-world', 'bg-hz-person');
DELETE FROM poetry_source WHERE id IN ('source-dushi-xiangzhu-05', 'source-quantangshi-201');
DELETE FROM poetry_schema_version WHERE version_no = 25;
COMMIT;
