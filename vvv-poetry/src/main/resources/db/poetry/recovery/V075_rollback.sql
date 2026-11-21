-- V075 精确回滚：只删 V075 插入的行（id 全枚举）。**零 source 删除**——
-- 本迁移零新建 source（V018 已立 source-ws-t300-363，V066 判例反向首枚）；
-- source-ws-t300-363 / source-quantangshi-128 / source-quantangshi-160 皆既有行，绝不删；
-- work-t300-363 本体与其 text_line 8 行都是 V018 的行，绝不删；
-- source-zizhi-tongjian-events 为他迁移所立，零删除。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-363-scene', 'claim-bg-363-city', 'claim-bg-363-world', 'claim-bg-363-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-363-scene', 'claim-bg-363-city', 'claim-bg-363-world', 'claim-bg-363-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-363-scene', 'bg-363-city', 'bg-363-world', 'bg-363-person');
DELETE FROM poetry_background WHERE id IN ('bg-363-scene', 'bg-363-city', 'bg-363-world', 'bg-363-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-363-scene', 'claim-bg-363-city', 'claim-bg-363-world', 'claim-bg-363-person');
DELETE FROM poetry_content WHERE id IN ('bg-363-scene', 'bg-363-city', 'bg-363-world', 'bg-363-person');
DELETE FROM poetry_schema_version WHERE version_no = 75;
COMMIT;
