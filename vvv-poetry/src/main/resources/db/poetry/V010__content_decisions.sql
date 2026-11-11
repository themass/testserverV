-- V010: 内容决定落地（《春望》15 条决定，见 docs/content/chun-wang/decisions-final.md）。
-- MySQL 5.6.40 兼容；刻意没有外键、JSON、CHECK、生成列。
-- 只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`；DDL 在 MySQL 不可回滚。
-- 前置：V009 已执行。每一条改动都单独写清了「为什么」和「回滚方式」。
--
-- ===== 本文件改什么 =====
--   1) OQ-08：place-chang-an 的 modern_name 从「西安」改为「今西安一带」。
--      理由：唐长安城不等于今西安城。原值让学生以为两者是同一处，是事实性错误。
--      展示用的那句话（dev-mock 的 note 必须与此逐字一致）：今西安一带：唐长安城不等于今西安城，不冒充等价。
--      这是一次 UPDATE，不改列结构，也不改任何 id。
--   2) OQ-14：补登记《旧唐书·杜甫传》为第 5 个来源（PENDING）。
--      理由：写作规范与样本规格都引用了《旧唐书》，但来源登记表里没有它。
--      登记不等于核验：verification_status 必须是 PENDING，locator 留空，等史料审核人填。
--   3) OQ-15：登记杜甫同期诗作作为「旁证」这一来源类别的占位记录（PENDING），篇目留空。
--      理由：旁证要用，但篇目必须由查证确定，不能凭记忆写。这条记录只表达「会有一个这样的来源」。
--
-- ===== 明确不做 =====
--   - 不改 V004 的任何行（迁移不可变；需要修正的用新迁移追加）。
--   - 不改 ANY claim 的 certainty。757/758 两说、精确年岁、「山河」范围仍是待核项，
--     它们是证据问题，不是迁移能解决的问题。
--   - 不改 poetry_source.verification_status 为 VERIFIED。核验只有人能做的部分，本文件不做。
--
-- ===== 执行前只读检查 =====
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;        -- 1..9 都在
--   SELECT id, modern_name FROM poetry_place WHERE id='place-chang-an';      -- 应为 '西安'
--   SELECT id,title FROM poetry_source WHERE id IN ('source-jiutangshu-dufu','source-dufu-contemporary-poem');
--                                                                            -- 都应为空
--
-- ===== 执行后核对 =====
--   SELECT modern_name FROM poetry_place WHERE id='place-chang-an';          -- '今西安一带'
--   SELECT id,verification_status FROM poetry_source WHERE id LIKE 'source-jiutangshu%' OR id LIKE 'source-dufu-contemporary%';
--                                                                            -- 两行,都是 PENDING
--   SELECT version_no FROM poetry_schema_version WHERE version_no=10;        -- 恰好一行
--
-- ===== 回滚 =====
--   db/poetry/recovery/V010_rollback.sql

-- ---------------------------------------------------------------------------
-- 1) OQ-08：长安今地名不是「西安」，是「今西安一带」
-- ---------------------------------------------------------------------------
UPDATE poetry_place SET modern_name = '今西安一带' WHERE id = 'place-chang-an';

-- ---------------------------------------------------------------------------
-- 2) OQ-14：《旧唐书·杜甫传》补登记（PENDING，locator 与核验由人完成）
-- ---------------------------------------------------------------------------
INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status)
SELECT 'source-jiutangshu-dufu', '《旧唐书·杜甫传》', '刘昫等', NULL, NULL,
       '公有领域古籍。卷次与引文须由史料审核人核对后填入 locator，本行只登记「有这个来源」。',
       'PENDING'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_source WHERE id = 'source-jiutangshu-dufu');

-- ---------------------------------------------------------------------------
-- 3) OQ-15：杜甫同期诗作（旁证）占位。篇目留空，不能凭记忆写。
-- ---------------------------------------------------------------------------
INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status)
SELECT 'source-dufu-contemporary-poem', '杜甫同期诗作（篇目待定）', '杜甫', NULL, NULL,
       '公有领域。只作旁证，不写成史书记述。具体篇目须由史料审核人查证后填入，本行不指定任何篇目。',
       'PENDING'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_source WHERE id = 'source-dufu-contemporary-poem');

-- ---------------------------------------------------------------------------
-- 版本账本
-- ---------------------------------------------------------------------------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 10, 'content decisions: chang-an modern name, Jiutangshu + contemporary-poem sources (PENDING)'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 10);
