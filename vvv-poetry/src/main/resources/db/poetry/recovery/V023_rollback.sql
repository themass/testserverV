-- V023 精确回滚：只删 V023 插入的行（id 全枚举）。work-t300-221 本体是 V018 的行，绝不删。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-sufu-scene', 'claim-bg-sufu-city', 'claim-bg-sufu-world', 'claim-bg-sufu-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-sufu-scene', 'claim-bg-sufu-city', 'claim-bg-sufu-world', 'claim-bg-sufu-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-sufu-scene', 'bg-sufu-city', 'bg-sufu-world', 'bg-sufu-person');
DELETE FROM poetry_background WHERE id IN ('bg-sufu-scene', 'bg-sufu-city', 'bg-sufu-world', 'bg-sufu-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-sufu-scene', 'claim-bg-sufu-city', 'claim-bg-sufu-world', 'claim-bg-sufu-person');
DELETE FROM poetry_content WHERE id IN ('bg-sufu-scene', 'bg-sufu-city', 'bg-sufu-world', 'bg-sufu-person');
DELETE FROM poetry_schema_version WHERE version_no = 23;
COMMIT;
