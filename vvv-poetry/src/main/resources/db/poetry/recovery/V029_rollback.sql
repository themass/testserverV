-- V029 精确回滚：只删 V029 插入的行（id 全枚举）；poetry_text_line 恢复 V018 原 5 行原值。
-- work-t300-234 本体是 V018 的行，绝不删；共用 source 行（jiutangshu-wenyuan/
-- xintangshu-wenyi/tongjian-events/source-ws-t300-234）都不删；V029 零 poetry_relation 行。
START TRANSACTION;
DELETE FROM poetry_claim_selection WHERE claim_id IN ('claim-bg-dy-scene', 'claim-bg-dy-city', 'claim-bg-dy-world', 'claim-bg-dy-person');
DELETE FROM poetry_citation WHERE claim_id IN ('claim-bg-dy-scene', 'claim-bg-dy-city', 'claim-bg-dy-world', 'claim-bg-dy-person');
DELETE FROM poetry_background_line WHERE background_id IN ('bg-dy-scene', 'bg-dy-city', 'bg-dy-world', 'bg-dy-person');
DELETE FROM poetry_background WHERE id IN ('bg-dy-scene', 'bg-dy-city', 'bg-dy-world', 'bg-dy-person');
DELETE FROM poetry_claim WHERE id IN ('claim-bg-dy-scene', 'claim-bg-dy-city', 'claim-bg-dy-world', 'claim-bg-dy-person');
DELETE FROM poetry_content WHERE id IN ('bg-dy-scene', 'bg-dy-city', 'bg-dy-world', 'bg-dy-person');
DELETE FROM poetry_source WHERE id IN ('source-quantangshi-052');

-- text_line 还原：删 V029 的 8 行，重插 V018 原 5 行（值原样枚举，逐字抄自 V018 SQL 3343–3351 行）
DELETE FROM poetry_text_line WHERE version_id = 'text-work-t300-234-ws';
INSERT INTO poetry_text_line (version_id, line_seq, content)
SELECT * FROM (
SELECT 'text-work-t300-234-ws' AS version_id, 1 AS line_seq, '陽月南飛雁，' AS content FROM DUAL
UNION ALL
SELECT 'text-work-t300-234-ws' AS version_id, 2 AS line_seq, '傳聞至此回。' AS content FROM DUAL
UNION ALL
SELECT 'text-work-t300-234-ws' AS version_id, 3 AS line_seq, '我行殊未已，何日復歸來？江靜潮初落，林昏瘴不開。' AS content FROM DUAL
UNION ALL
SELECT 'text-work-t300-234-ws' AS version_id, 4 AS line_seq, '明朝望鄉處，' AS content FROM DUAL
UNION ALL
SELECT 'text-work-t300-234-ws' AS version_id, 5 AS line_seq, '應見隴頭梅。' AS content FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_text_line x WHERE x.version_id = t.version_id AND x.line_seq = t.line_seq);
DELETE FROM poetry_schema_version WHERE version_no = 29;
COMMIT;
