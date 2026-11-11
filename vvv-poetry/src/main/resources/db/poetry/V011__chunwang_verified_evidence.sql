-- V011：《春望》的真实定位与原文证据（2026-11-12，AI 对照原文核对的结果）。MySQL 5.6.40 兼容。
-- 只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`；DDL/DML 无法整体回滚。
-- 前置：V010 已执行（本文件更新 V010 登记的 source-jiutangshu-dufu）。
--
-- ===== 本文件做什么，不做什么 =====
-- 做：登记真实的来源版本与网址；把引用里的「待人工核对」换成真实卷次，并附上从原文逐字摘出的证据句。
-- 不做：**不把任何来源改成 VERIFIED。** 核验必须走 Studio 的 verifySource（它会过发布门禁、跑完整性审计、
--       写评审日志）；直接 UPDATE verification_status 会绕过这三样。核验由 scripts/db/verify-sources.sh 触发。
-- 不做：不改任何 claim 的 certainty/status，不发布任何东西，不改 V004（迁移不可变）。
--
-- ===== 核对用的原文（可复现）=====
--   诗文   维基文库《全唐詩》卷二百二十四（https://zh.wikisource.org/wiki/全唐詩/卷224）
--          与本机 chinese-poetry 的「全唐诗/poet.tang.11000.json」「御定全唐詩/json/224.json」三处逐字一致，
--          与库里 text-chun-wang-draft 的 8 句逐字一致（繁→简后）。
--   旧唐书 维基文库《舊唐書》卷一百九十下 列傳第一百四十下 文苑下·杜甫
--   新唐书 维基文库《新唐書》卷二百一 列傳第一百二十六 文藝上·杜甫
--   ⚠ 维基文库的《舊唐書》页面标注「未校对」（页面自述质量约 25%），个别字可能是录入异体或错字。
--     证据句是从该页面原文逐字摘出的，含异体字（如「䧟」「徴」），没有改写；正式发布前建议再对一次影印本。
--
-- ===== 明确没有核到的（仍是 PENDING，不得写成事实）=====
--   - 《春望》的写作年份。上面三份材料都不给这首诗的系年。
--   - 杜甫的生卒年。旧唐书说永泰二年（766）卒、享年五十九，新唐书只说「大历中」卒、享年五十九，两说互相矛盾，
--     且都没写生年。因此「四十多岁」也推不出来，已从台词里删掉。
--   - 安史之乱的起讫、战事时长、驿路是否断绝：需要《资治通鉴》，未核。
--   - 「山河」的范围、长安今地名的等价关系：需要注本，未核。
--
-- ===== 一个纪年错误（不是史料分歧）=====
--   claim-chun-wang-time-758 的文字写「至德元载说」。至德元载是 756 年，758 年是乾元元年，二者对不上。
--   本文件只更正这条 claim 的文字标签，不改年份数字、不判断哪一说成立。
--
-- ===== 执行前只读检查 =====
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;      -- 1..10 都在，没有 11
--   SELECT id, verification_status FROM poetry_source WHERE id='source-quantangshi-224';   -- 应为空
--
-- ===== 执行后核对 =====
--   SELECT COUNT(*) FROM poetry_citation WHERE locator LIKE '待%';          -- 比执行前少 2（作者归属、新唐书·个人处境两条
--                                                                       -- 被换成真实定位；新插入的 3 条旧唐书引用本来就不是占位）
--   SELECT COUNT(*) FROM poetry_citation WHERE source_id='source-jiutangshu-dufu';   -- 3
--   SELECT version_no FROM poetry_schema_version WHERE version_no=11;       -- 恰好一行
--   SELECT id, verification_status FROM poetry_source WHERE id IN
--     ('source-quantangshi-224','source-jiutangshu-dufu','source-dufu-zhuan-candidate');   -- 三行，都是 PENDING
--
-- ===== 回滚 =====
--   db/poetry/recovery/V011_rollback.sql

-- ---------------------------------------------------------------------------
-- 1) 诗文底本：《全唐诗》卷二百二十四（PENDING，等 verifySource）
-- ---------------------------------------------------------------------------
INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status, source_kind, reliability)
SELECT 'source-quantangshi-224', '《全唐诗》卷二百二十四', NULL,
       '御定全唐詩（维基文库录入本，与 chinese-poetry 御定全唐詩卷二百二十四一致）',
       'https://zh.wikisource.org/wiki/全唐詩/卷224',
       '公有领域古籍。reliability 是编者对「清编唐诗总集」的分级判断，不代表本条已核验。',
       'PENDING', 'ANTHOLOGY', 'HIGH'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_source WHERE id = 'source-quantangshi-224');

UPDATE poetry_text_version
   SET source_id = 'source-quantangshi-224',
       source_locator = '卷二百二十四·杜甫·春望（全诗八句）',
       label = '简体录入（据《全唐诗》卷二百二十四，繁简转换后逐字一致）'
 WHERE id = 'text-chun-wang-draft' AND status = 'DRAFT';

-- 作者归属 claim 改引全唐诗（原引用只指向一个「待核对版本」的维基文库入口）
UPDATE poetry_citation
   SET source_id = 'source-quantangshi-224',
       locator = '卷二百二十四·杜甫·春望',
       evidence_excerpt = '春望　杜甫：國破山河在，城春草木深。感時花濺淚，恨別鳥驚心。烽火連三月，家書抵萬金。白頭搔更短，渾欲不勝簪。'
 WHERE claim_id = 'claim-chun-wang-author' AND source_id = 'source-chun-wang-candidate';

-- ---------------------------------------------------------------------------
-- 2) 《旧唐书·杜甫传》：补全版本与网址，并给出可核对的原文
-- ---------------------------------------------------------------------------
UPDATE poetry_source
   SET edition = '舊唐書卷一百九十下 列傳第一百四十下 文苑下（维基文库录入本，页面标注未校对）',
       url = 'https://zh.wikisource.org/wiki/舊唐書/卷190下'
 WHERE id = 'source-jiutangshu-dufu' AND verification_status = 'PENDING';

INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT 'claim-bg-person', 'source-jiutangshu-dufu', '卷一百九十下·杜甫传',
       '十五載，禄山䧟京師，肅宗徴兵靈武，甫自京師宵遁赴河西謁肅宗，於彭原郡拜右拾遺'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_citation
  WHERE claim_id = 'claim-bg-person' AND source_id = 'source-jiutangshu-dufu');

INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT 'claim-bg-city', 'source-jiutangshu-dufu', '卷一百九十下·杜甫传',
       '十五載，禄山䧟京師，肅宗徴兵靈武，甫自京師宵遁赴河西謁肅宗，於彭原郡拜右拾遺'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_citation
  WHERE claim_id = 'claim-bg-city' AND source_id = 'source-jiutangshu-dufu');

-- 长安陷落年份：天宝十五载 = 公元 756（天宝元年 742 起算）。纪年换算写在 locator 里，证据句仍是原文。
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT 'claim-chang-an-capture-time', 'source-jiutangshu-dufu', '卷一百九十下·杜甫传（天宝十五载=公元756，纪年换算）',
       '十五載，禄山䧟京師，肅宗徴兵靈武，甫自京師宵遁赴河西謁肅宗，於彭原郡拜右拾遺'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_citation
  WHERE claim_id = 'claim-chang-an-capture-time' AND source_id = 'source-jiutangshu-dufu');

-- ---------------------------------------------------------------------------
-- 3) 《新唐书·杜甫传》：补全版本与网址；个人处境 claim 的占位定位换成真实原文
-- ---------------------------------------------------------------------------
UPDATE poetry_source
   SET edition = '新唐書卷二百一 列傳第一百二十六 文藝上（维基文库录入本）',
       url = 'https://zh.wikisource.org/wiki/新唐書/卷201'
 WHERE id = 'source-dufu-zhuan-candidate' AND verification_status = 'PENDING';

UPDATE poetry_citation
   SET locator = '卷二百一·文藝上·杜甫传',
       evidence_excerpt = '時所在寇奪，甫家寓鄜，彌年艱窶，孺弱至餓死；肅宗立，自鄜州羸服欲奔行在，為賊所得'
 WHERE claim_id = 'claim-bg-person' AND source_id = 'source-dufu-zhuan-candidate'
   AND locator LIKE '待%';

-- ---------------------------------------------------------------------------
-- 4) 纪年标签更正：至德元载 = 756，不是 758。只改文字标签，不改年份数字，也不判断哪一说成立。
-- ---------------------------------------------------------------------------
UPDATE poetry_claim
   SET value_text = '758..758 (EXACT) 说二：系于乾元元年（原标签「至德元载」与 758 年对不上：至德元载是 756 年）'
 WHERE id = 'claim-chun-wang-time-758'
   AND value_text = '758..758 (EXACT) 说二：至德元载说，另有年谱系于此年';

-- ---------------------------------------------------------------------------
-- 版本账本
-- ---------------------------------------------------------------------------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 11, 'chun-wang evidence: Quantangshi 224 + Jiu/Xin Tangshu locators and excerpts (sources stay PENDING)'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 11);
