-- V030 精确回滚：删 V030 的 12 行，重插 V018 原 9 行（值逐字解析自 V018 SQL 原文，非手抄）。
-- work-t300-291 本体与其 version/source/claim 行都是 V018 的，绝不删。
START TRANSACTION;

DELETE FROM poetry_text_line WHERE version_id = 'text-work-t300-291-ws';

INSERT INTO poetry_text_line (version_id, line_seq, content)
SELECT * FROM (
SELECT 'text-work-t300-291-ws' AS version_id, 1 AS line_seq, '吏舍跼終年，' AS content FROM DUAL
UNION ALL
SELECT 'text-work-t300-291-ws' AS version_id, 2 AS line_seq, '出郊曠清曙。' AS content FROM DUAL
UNION ALL
SELECT 'text-work-t300-291-ws' AS version_id, 3 AS line_seq, '楊柳散和風，' AS content FROM DUAL
UNION ALL
SELECT 'text-work-t300-291-ws' AS version_id, 4 AS line_seq, '青山澹吾慮。' AS content FROM DUAL
UNION ALL
SELECT 'text-work-t300-291-ws' AS version_id, 5 AS line_seq, '依叢適自憩，' AS content FROM DUAL
UNION ALL
SELECT 'text-work-t300-291-ws' AS version_id, 6 AS line_seq, '緣澗還復去。' AS content FROM DUAL
UNION ALL
SELECT 'text-work-t300-291-ws' AS version_id, 7 AS line_seq, '微雨靄芳原，春鳩鳴何處？樂幽心屢止，遵事跡猶遽。' AS content FROM DUAL
UNION ALL
SELECT 'text-work-t300-291-ws' AS version_id, 8 AS line_seq, '終罷斯結廬，' AS content FROM DUAL
UNION ALL
SELECT 'text-work-t300-291-ws' AS version_id, 9 AS line_seq, '慕陶真可庶。' AS content FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_text_line x WHERE x.version_id = t.version_id AND x.line_seq = t.line_seq);

DELETE FROM poetry_schema_version WHERE version_no = 30;
COMMIT;
