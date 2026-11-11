-- V012：读者可见文字的清理（2026-11-12）。MySQL 5.6.40 兼容。
-- 只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V011 已执行。
--
-- ===== 为什么 =====
-- AI 审核（content-review）发现：4 条背景、2 条注释的正文里带着给编辑看的内部标记（「草稿」「待复核」「措辞待核」），
-- 学生端会把这些正文原样给读者看。其中几处还说了没有依据的话：
--   - 「长满了没人打理的街巷」「宫阙、街市、官署还在，但秩序已经不在了」：诗里没有，也没有来源；
--   - 「官职低微」：没有核到；「755年打到763年」「前后多年」「音信断绝是常态」：需要《资治通鉴》，未核；
--   - 注释「山河：指长安一带的山川」：已定的 OQ-09 是「不限定范围」，这一句限定了；
--   - 标题「四十六岁的杜甫」「打了三年的战事」：年龄与年数都无依据。
-- 新文字只保留两类：诗句本身写到的，和已对照旧唐书/新唐书核到的（被困长安、家人留在鄜州）。
--
-- ===== 保护 =====
-- 每条 UPDATE 都要求：旧文字与 V004 逐字一致，且内容不是 PUBLISHED。任何一个条件不成立，该条什么也不做。
-- 迁移不得悄悄改写已发布的文字——已发布的修改必须走评审。
--
-- ===== 不做 =====
-- 不改 claim 的 certainty/status，不改引用，不动 V004，不核验任何来源。
--
-- ===== 执行前只读检查 =====
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 11，不含 12
--   SELECT COUNT(*) FROM poetry_background WHERE body_text LIKE '%草稿%';   -- 应为 4
--
-- ===== 执行后核对 =====
--   SELECT COUNT(*) FROM poetry_background WHERE body_text LIKE '%草稿%' OR body_text LIKE '%待%';  -- 0
--   SELECT COUNT(*) FROM poetry_annotation WHERE content LIKE '%待%';                              -- 0
--   SELECT version_no FROM poetry_schema_version WHERE version_no = 12;                            -- 恰好一行
--
-- 回滚：recovery/V012_rollback.sql（同样带旧文字保护）

UPDATE poetry_background SET body_text = '山河还在，城里的草木在春天长得很深。'
 WHERE id = 'bg-chun-wang-scene' AND body_text = '城还在，山和河也还在，可它已经不是从前的样子。春天照常来了，草木疯长，长满了没人打理的街巷。（草稿：以景物反衬，措辞待复核）'
   AND NOT EXISTS (SELECT 1 FROM poetry_content c WHERE c.id = poetry_background.id AND c.status = 'PUBLISHED');

UPDATE poetry_background SET body_text = '叛军攻下长安之后，杜甫被困在这座城里。'
 WHERE id = 'bg-chun-wang-city' AND body_text = '长安是帝国的心脏。都城被占之后，宫阙、街市、官署还在，但秩序已经不在了。（草稿：城市作为处境，需核对城况史源）'
   AND NOT EXISTS (SELECT 1 FROM poetry_content c WHERE c.id = poetry_background.id AND c.status = 'PUBLISHED');

UPDATE poetry_background SET body_text = '诗里说“烽火连三月，家书抵万金”：战火不停，一封家信比万金还难得。'
 WHERE id = 'bg-chun-wang-world' AND body_text = '这场战事从755年打到763年（通行纪年，待核），前后多年，音信断绝是常态。"家书抵万金"不是夸张的说法，是当时的实际处境。（草稿）'
   AND NOT EXISTS (SELECT 1 FROM poetry_content c WHERE c.id = poetry_background.id AND c.status = 'PUBLISHED');

UPDATE poetry_background SET body_text = '他被困在长安，家人留在鄜州。'
 WHERE id = 'bg-chun-wang-person' AND body_text = '写这首诗时杜甫正困在长安一带，官职低微、家人离散。（草稿：具体年份与官职待年谱核对，不假设确定故事）'
   AND NOT EXISTS (SELECT 1 FROM poetry_content c WHERE c.id = poetry_background.id AND c.status = 'PUBLISHED');

UPDATE poetry_annotation SET content = '山河：山和河，指大地山川。'
 WHERE id = 'ann-chun-wang-shanhe' AND content = '山河：指长安一带的山川。（措辞待与权威注本核对）'
   AND claim_id IN (SELECT id FROM poetry_claim WHERE status <> 'PUBLISHED');

UPDATE poetry_annotation SET content = '烽火：战火，这里指战事。'
 WHERE id = 'ann-chun-wang-fenghuo' AND content = '烽火：战火，这里指持续未平的战事。（措辞待核）'
   AND claim_id IN (SELECT id FROM poetry_claim WHERE status <> 'PUBLISHED');

UPDATE poetry_claim SET value_text = '山河：山和河，指大地山川。'
 WHERE id = 'claim-ann-shanhe' AND value_text = '山河：指长安一带的山川。' AND status <> 'PUBLISHED';

UPDATE poetry_claim SET value_text = '烽火：战火，借指战事。'
 WHERE id = 'claim-ann-fenghuo' AND value_text = '烽火：战火，借指持续的战事。' AND status <> 'PUBLISHED';

UPDATE poetry_content SET title = '这个天下：战火不停'
 WHERE id = 'bg-chun-wang-world' AND title = '这个天下：打了三年的战事' AND status <> 'PUBLISHED';

UPDATE poetry_content SET title = '这个人：被困在长安的杜甫'
 WHERE id = 'bg-chun-wang-person' AND title = '这个人：四十六岁的杜甫' AND status <> 'PUBLISHED';

INSERT INTO poetry_schema_version (version_no, description)
SELECT 12, 'reader-visible text cleanup: no internal markers, no unsourced claims'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 12);
