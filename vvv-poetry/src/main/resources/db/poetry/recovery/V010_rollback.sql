-- V010 的回滚。只在确实需要退回时执行；DDL 与 DML 都不可自动撤销。
-- 顺序：先回滚应用代码（如果它依赖 V010 的改动），再执行本文件。
--
-- 本文件只撤销 V010 自己做的事，且是「尽力还原」而不是保证回到执行前一刻：
--   1) modern_name 还原为 '西安'（V004 的原值）。
--   2) 删除本文件新增的两个来源。若它们已经被人填上 locator 或被 claim 引用，
--      删除会破坏引用完整性（本项目没有外键，数据库不会拦你），所以带 NOT EXISTS 保护：
--      一旦有 claim/citation 引用，本语句什么也不做，留给人工处理。
--   3) 不删除 version_no=10 的账本行 —— 留着这一行才能看出「曾经执行过 V010」。
--      若要彻底抹掉痕迹，需人工确认后单独删除，并在变更记录里写明。
--
-- 执行前先看：
--   SELECT COUNT(*) FROM poetry_citation WHERE source_id IN
--     ('source-jiutangshu-dufu','source-dufu-contemporary-poem');

UPDATE poetry_place SET modern_name = '西安' WHERE id = 'place-chang-an';

DELETE FROM poetry_source
 WHERE id IN ('source-jiutangshu-dufu', 'source-dufu-contemporary-poem')
   AND NOT EXISTS (
       SELECT 1 FROM poetry_citation c WHERE c.source_id = poetry_source.id
   );
