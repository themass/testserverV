-- V013：核到的断言登记真实定位；核不到的老实降级（2026-11-12）。MySQL 5.6.40 兼容。
-- 只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。前置：V012 已执行。
--
-- ===== 核对用的原文（可复现）=====
--   维基文库《舊唐書》卷一 本紀第一 高祖  https://zh.wikisource.org/wiki/舊唐書/卷1
--   维基文库《舊唐書》卷九 本紀第九 玄宗下 https://zh.wikisource.org/wiki/舊唐書/卷9
--   维基文库《舊唐書》卷二十下 本紀第二十下 哀帝 https://zh.wikisource.org/wiki/舊唐書/卷20下
--   ⚠ 维基文库的《舊唐書》录入本多处标注未校对；证据句是逐字摘出的，含异体字，没有改写。
--
-- ===== 核到了 =====
--   唐朝 618..907   起点：卷一「改隋義寧二年為唐武德元年」（義寧二年=618）；终点：卷二十下 天祐四年的禅位诏（天祐四年=907，天祐元年=904 起算）。
--   安史之乱起点 755 卷九 天寶十四載（天寶元年=742）十一月：安祿山率兵十餘萬自幽州南向。
-- ===== 没核到 =====
--   安史之乱终点 763。《舊唐書》卷十一的录入本里，「賊范陽尹李懷仙斬史朝義首來獻」落在「寶應元年」一节（寶應元年=762），
--   而通行说法是 763；该录入本的节标题与内容也对不上（「廣德元年」标题下直接写「二年春」）。这份文本不足以裁决，
--   所以终点不登记定位，两条含终点的断言把 certainty 从 KNOWN 降为 LIKELY，等对影印本或《資治通鑑》。
--
-- ===== 不做 =====
--   不核验任何来源（走 verifySource），不改 status，不动 V004，不改写任何已发布内容。
--   降级只作用于 status<>'PUBLISHED' 且当前为 KNOWN 的行。
--
-- ===== 执行前/后 =====
--   前: SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 12，不含 13
--   后: SELECT id, certainty FROM poetry_claim WHERE id IN ('claim-anshi-time','claim-theme-anshi-time');   -- 都是 LIKELY
--   后: SELECT COUNT(*) FROM poetry_citation WHERE source_id = 'source-jiutangshu-benji';   -- 4
-- 回滚: recovery/V013_rollback.sql

INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status, source_kind, reliability)
SELECT 'source-jiutangshu-benji', '《舊唐書》本紀（卷一、卷九、卷二十下）', '劉昫等',
       '维基文库录入本，页面标注未校对；证据句取自原文，含异体字',
       'https://zh.wikisource.org/wiki/舊唐書',
       '公有领域古籍。reliability 是编者对正史本纪的分级判断，不代表本条已核验。', 'PENDING', 'OFFICIAL_HISTORY', 'HIGH'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_source WHERE id = 'source-jiutangshu-benji');

INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT 'claim-tang-time', 'source-jiutangshu-benji', '卷一·高祖本紀（武德元年=618）；卷二十下·哀帝本紀（天祐四年=907）',
       '甲子，高祖即皇帝位於太極殿，命刑部尚書蕭造兼太尉，告於南郊，大赦天下，改隋義寧二年為唐武德元年；朕敬以天下，傳禪聖君，退居舊籓，以備三恪'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_citation WHERE claim_id = 'claim-tang-time' AND source_id = 'source-jiutangshu-benji');

INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT 'claim-anshi-time', 'source-jiutangshu-benji', '卷九·玄宗下·天寶十四載十一月（天寶十四載=755，纪年换算）；仅核到起点，终点 763 未核',
       '范陽節度使安祿山率蕃、漢之兵十餘萬，自幽州南向詣闕，以誅楊國忠為名'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_citation WHERE claim_id = 'claim-anshi-time' AND source_id = 'source-jiutangshu-benji');

INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT 'claim-theme-anshi-time', 'source-jiutangshu-benji', '卷九·玄宗下·天寶十四載十一月（天寶十四載=755，纪年换算）；仅核到起点，终点 763 未核',
       '范陽節度使安祿山率蕃、漢之兵十餘萬，自幽州南向詣闕，以誅楊國忠為名'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_citation WHERE claim_id = 'claim-theme-anshi-time' AND source_id = 'source-jiutangshu-benji');

UPDATE poetry_claim SET certainty = 'LIKELY'
 WHERE id = 'claim-anshi-time' AND certainty = 'KNOWN' AND status <> 'PUBLISHED';

UPDATE poetry_claim SET certainty = 'LIKELY'
 WHERE id = 'claim-theme-anshi-time' AND certainty = 'KNOWN' AND status <> 'PUBLISHED';

INSERT INTO poetry_schema_version (version_no, description)
SELECT 13, 'dynasty and rebellion start dates cited from Jiu Tangshu annals, unverified range ends downgraded to LIKELY'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 13);
