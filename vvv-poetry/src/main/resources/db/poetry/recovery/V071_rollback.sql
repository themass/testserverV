-- V071 精确回滚：只删 V071 插入的行（id 全枚举）。
-- **零 source 删除**：source-ws-t300-010（V018 所立的 ws 选本页源）与
-- source-quantangshi-539（V018 所立的卷539 卷页源）本迁移皆复用，绝不删；
-- work-t300-010 本体、其 text_line 8 行都是 V018 的行，绝不删；
-- source-zizhi-tongjian-events / source-jiutangshu-wenyuan 为他迁移所立，零删除。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-010-scene', 'claim-bg-010-city', 'claim-bg-010-world', 'claim-bg-010-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-010-scene', 'claim-bg-010-city', 'claim-bg-010-world', 'claim-bg-010-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-010-scene', 'bg-010-city', 'bg-010-world', 'bg-010-person');
DELETE FROM poetry_background WHERE id IN ('bg-010-scene', 'bg-010-city', 'bg-010-world', 'bg-010-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-010-scene', 'claim-bg-010-city', 'claim-bg-010-world', 'claim-bg-010-person');
DELETE FROM poetry_content WHERE id IN ('bg-010-scene', 'bg-010-city', 'bg-010-world', 'bg-010-person');
DELETE FROM poetry_schema_version WHERE version_no = 71;
COMMIT;
