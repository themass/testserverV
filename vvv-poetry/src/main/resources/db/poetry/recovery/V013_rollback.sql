-- V013 回滚：删除本迁移加的引用，把降级的 certainty 还原为 KNOWN。不删除 version_no=13 的账本行。
-- 若 source-jiutangshu-benji 已被核验或被其它引用使用，来源行保留，只删本迁移加的引用。
UPDATE poetry_claim SET certainty = 'KNOWN'
 WHERE id IN ('claim-anshi-time', 'claim-theme-anshi-time') AND certainty = 'LIKELY' AND status <> 'PUBLISHED';

DELETE FROM poetry_citation WHERE source_id = 'source-jiutangshu-benji'
 AND claim_id IN ('claim-tang-time', 'claim-anshi-time', 'claim-theme-anshi-time');

DELETE FROM poetry_source WHERE id = 'source-jiutangshu-benji' AND verification_status = 'PENDING'
 AND NOT EXISTS (SELECT 1 FROM poetry_citation c WHERE c.source_id = 'source-jiutangshu-benji');
