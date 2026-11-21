-- V028 精确回滚：只删 V028 插入的行（id 全枚举）。work-t300-002 本体是 V018 的行，绝不删；
-- 共用 source 行（jiutangshu-wenyuan/xintangshu-wenyi/tongjian-events/source-ws-t300-002）都不删；
-- V028 零 poetry_relation 行，故无需删 relation。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-yz-scene', 'claim-bg-yz-city', 'claim-bg-yz-world', 'claim-bg-yz-person', 'claim-event-tang-khitans-invasion-time');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-yz-scene', 'claim-bg-yz-city', 'claim-bg-yz-world', 'claim-bg-yz-person', 'claim-event-tang-khitans-invasion-time');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-yz-scene', 'bg-yz-city', 'bg-yz-world', 'bg-yz-person');
DELETE FROM poetry_background WHERE id IN ('bg-yz-scene', 'bg-yz-city', 'bg-yz-world', 'bg-yz-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-yz-scene', 'claim-bg-yz-city', 'claim-bg-yz-world', 'claim-bg-yz-person', 'claim-event-tang-khitans-invasion-time');
DELETE FROM poetry_content WHERE id IN ('bg-yz-scene', 'bg-yz-city', 'bg-yz-world', 'bg-yz-person', 'event-tang-khitans-invasion');
DELETE FROM poetry_source WHERE id IN ('source-quantangshi-083');
DELETE FROM poetry_schema_version WHERE version_no = 28;
COMMIT;
