-- V030：纯修复迁移——text-work-t300-291-ws（韋應物《東郊》）9 行并句 → 12 行。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V018 已执行；且《東郊》两对页内异文 {另|斯|期}/{另|真|直} 已先登记于
--   corpus/tang300-variants.md（「東郊 291」行，2026-11-20）——先登记后修形，顺序不可反。
--
-- 缺陷：V018 对 291 落 poetry_text_line 时 line_seq 7 误并四句为一行
--   （'微雨靄芳原，春鳩鳴何處？樂幽心屢止，遵事跡猶遽。'），12 句只落 9 行。
--   全库此形状仅 234、291 两例；234 已在 V029 修复，本迁移修 291。
--   grep 实测：全库只有 V018 与其回滚引用 text-work-t300-291-ws——删旧插新安全。
--
-- 数据源（机器核对，两侧都不手抄）：新 12 行由 emit_v030.py 对 ws 快照
--   /tmp/src-dl/ws-poems/東郊.txt 的 <poem> 块折叠 {{另|首|次}}→首 后按标点机械切分；
--   回滚旧 9 行由同一脚本直接解析 V018 SQL 原文。新行正文取页内首读（斯/真），
--   与 V018 既定路线一致——本迁移只改分行形状，不动一个字。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 29，不含 30
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-291-ws';  -- 恰 9（缺陷行）
--   SELECT content FROM poetry_text_line WHERE version_id='text-work-t300-291-ws' AND line_seq=7;
--     -- 恰为上面那行 24 字并句
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-291-ws';  -- 12
--   SELECT content FROM poetry_text_line WHERE version_id='text-work-t300-291-ws'
--     AND line_seq IN (11,12);  -- '終罷斯結廬，' / '慕陶真可庶。'（首读）
-- 回滚: recovery/V030_rollback.sql（删 12 插 9——9 行值逐字解析自 V018 原文；不动 V018 其他行）
START TRANSACTION;

-- ---------- 修复：删缺陷 9 行，重插 12 行（逐字对折叠后的 ws <poem> 块） ----------
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
SELECT 'text-work-t300-291-ws' AS version_id, 7 AS line_seq, '微雨靄芳原，' AS content FROM DUAL
UNION ALL
SELECT 'text-work-t300-291-ws' AS version_id, 8 AS line_seq, '春鳩鳴何處？' AS content FROM DUAL
UNION ALL
SELECT 'text-work-t300-291-ws' AS version_id, 9 AS line_seq, '樂幽心屢止，' AS content FROM DUAL
UNION ALL
SELECT 'text-work-t300-291-ws' AS version_id, 10 AS line_seq, '遵事跡猶遽。' AS content FROM DUAL
UNION ALL
SELECT 'text-work-t300-291-ws' AS version_id, 11 AS line_seq, '終罷斯結廬，' AS content FROM DUAL
UNION ALL
SELECT 'text-work-t300-291-ws' AS version_id, 12 AS line_seq, '慕陶真可庶。' AS content FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_text_line x WHERE x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 版本账本 ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 30, 'pure repair migration for text-work-t300-291-ws (Wei Yingwu Dong-jiao, qi-jin-gu regulated-style): V018 mis-merged four poem-lines into line_seq 7 so twelve lines landed as nine rows -- the corpus scan in V029 found this shape only for works 234 and 291, and 234 was repaired inside V029; the two page-internal variants of this poem were registered first in corpus/tang300-variants.md as required (register-before-reshape), new rows keep the page first-reading (Si/Zhen) exactly as V018 chose, so the repair changes line shape only, not a single character of the stored text'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 30);
COMMIT;
