-- V056 精确回滚：只删 V056 插入的行（id 全枚举）。
-- work-t300-331 本体、其 text_line 4 行与 source-ws-t300-331 都是 V018 的行，绝不删；
-- 全部三个共用 source 行（ws-331/xintangshu-wenyuan/
-- zizhi-tongjian-events）均为他迁移所立，零删除（本迁移零新 source；卷184 无源行）；V056 零 relation。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-331-scene', 'claim-bg-331-city', 'claim-bg-331-world', 'claim-bg-331-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-331-scene', 'claim-bg-331-city', 'claim-bg-331-world', 'claim-bg-331-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-331-scene', 'bg-331-city', 'bg-331-world', 'bg-331-person');
DELETE FROM poetry_background WHERE id IN ('bg-331-scene', 'bg-331-city', 'bg-331-world', 'bg-331-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-331-scene', 'claim-bg-331-city', 'claim-bg-331-world', 'claim-bg-331-person');
DELETE FROM poetry_content WHERE id IN ('bg-331-scene', 'bg-331-city', 'bg-331-world', 'bg-331-person');
DELETE FROM poetry_schema_version WHERE version_no = 56;
COMMIT;
