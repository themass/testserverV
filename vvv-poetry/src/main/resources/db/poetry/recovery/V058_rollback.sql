-- V058 精确回滚：只删 V058 插入的行（id 全枚举），含本迁移新立的 source-quantangshi-183。
-- work-t300-330 本体、其 text_line 8 行与 source-ws-t300-330 都是 V018 的行，绝不删；
-- 其余三个共用 source 行（ws-330/xintangshu-wenyuan/zizhi-tongjian-events）
-- 均为他迁移所立，零删除；V058 零 relation。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-330-scene', 'claim-bg-330-city', 'claim-bg-330-world', 'claim-bg-330-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-330-scene', 'claim-bg-330-city', 'claim-bg-330-world', 'claim-bg-330-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-330-scene', 'bg-330-city', 'bg-330-world', 'bg-330-person');
DELETE FROM poetry_background WHERE id IN ('bg-330-scene', 'bg-330-city', 'bg-330-world', 'bg-330-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-330-scene', 'claim-bg-330-city', 'claim-bg-330-world', 'claim-bg-330-person');
DELETE FROM poetry_content WHERE id IN ('bg-330-scene', 'bg-330-city', 'bg-330-world', 'bg-330-person');
DELETE FROM poetry_source WHERE id = 'source-quantangshi-183';  -- 本迁移新立，删之
DELETE FROM poetry_schema_version WHERE version_no = 58;
COMMIT;
