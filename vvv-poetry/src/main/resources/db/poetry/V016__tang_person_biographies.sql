-- V016：唐朝诗人小传（阶段 B 第一批 7 位）。MySQL 5.6.40 兼容。
-- 只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。前置：V014、V015 已执行。
--
-- 数据源（可复现）：
--   content-agent/pipeline/data/chronology/tang-persons.json
--   （每条引文已对维基文库 wikitext 快照逐字核验，见 validate.py 的 persons 段）
--   生成：python3 emit_v016.py
--
-- 写入：7 个 PERSON 实体（新增 6 个；杜甫沿用 V002 的 person-du-fu 行，不删不重建）；
--       生平属性断言 39 条（certainty 记核验结果：两史一致且年份由已核年号表钉到具体年=KNOWN，
--       两史不同或史文只给含糊年代=LIKELY，值里写明「兩說並列」或「單源」）；
--       每条断言引用旧唐书文苑/新唐书文艺的逐字原文；
--       经历 EXPERIENCE 3 条（人 × 阶段 A 已录事件，依据是本人本传的逐字原文）。
-- 不做：不核验来源、不改 status、不加没有出处的句子；
--       不写生卒年——本批 7 人无一人两史给出一致的卒年，poetry_content 的年份一律 UNKNOWN/留空；
--       person-du-fu 在 V004 里的 712..770 APPROXIMATE 草稿值本迁移不动（它没有出处支持，也没有被证伪）。
--
-- 执行前: SELECT version_no FROM poetry_schema_version ORDER BY version_no;  -- 含 15，不含 16
-- 执行后: SELECT COUNT(*) FROM poetry_content WHERE entity_type='PERSON' AND (id LIKE 'person-tang-%' OR id='person-du-fu');  -- 30
--         SELECT COUNT(*) FROM poetry_claim WHERE subject_id IN ('person-tang-li-bai', 'person-du-fu', 'person-tang-wang-wei', 'person-tang-li-shangyin', 'person-tang-meng-haoran', 'person-tang-wang-changling', 'person-tang-cui-hao');  -- 42
-- 回滚: recovery/V016_rollback.sql
START TRANSACTION;

-- ---------- sources ----------
INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status, source_kind, reliability)
SELECT 'source-jiutangshu-wenyuan', '《舊唐書》列傳第一百四十 文苑（卷190上、190中、190下）', '劉昫等', '维基文库录入本，页面标注未校对；{{YL|}}、{{SKchar|}}、-{…}- 等录入标记在引文中原样保留', 'https://zh.wikisource.org/wiki/舊唐書/卷190下',
       '公有领域古籍。reliability 是编者对正史列传的分级判断，不代表本条已走 verifySource。', 'PENDING', 'OFFICIAL_HISTORY', 'HIGH'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_source WHERE id = 'source-jiutangshu-wenyuan');
INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status, source_kind, reliability)
SELECT 'source-xintangshu-wenyi', '《新唐書》列傳第一百二十六至一百二十八 文藝（卷201、202、203）', '歐陽修、宋祁等', '维基文库录入本；引文逐字摘自 wikitext，-{…}- 为录入本的繁简转换标记', 'https://zh.wikisource.org/wiki/新唐書/卷202',
       '公有领域古籍。与旧唐书并列使用：一致的记 KNOWN，不同的两说并列。reliability 不代表已核验。', 'PENDING', 'OFFICIAL_HISTORY', 'HIGH'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_source WHERE id = 'source-xintangshu-wenyi');

-- ---------- persons (PERSON) ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, start_year, end_year, time_precision)
SELECT * FROM (
SELECT 'person-tang-li-bai' AS id, 'PERSON' AS entity_type, 'tang-li-bai' AS slug, '李白' AS title, '字太白。天宝初待诏翰林，后因永王璘事长流夜郎。旧唐书说醉死于宣城，新唐书说代宗立时已卒、年六十余；出生地两史不同。' AS summary, CAST(NULL AS SIGNED) AS start_year, CAST(NULL AS SIGNED) AS end_year, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'person-du-fu' AS id, 'PERSON' AS entity_type, 'du-fu' AS slug, '杜甫' AS title, '字子美，本襄阳人、后徙河南巩县。天宝初应进士不第，天宝十五载陷贼中奔灵武拜右拾遗。两史同记卒于耒阳、年五十九，但卒年一旧作永泰二年、一新作大历中，两说并列。' AS summary, CAST(NULL AS SIGNED) AS start_year, CAST(NULL AS SIGNED) AS end_year, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'person-tang-wang-wei' AS id, 'PERSON' AS entity_type, 'tang-wang-wei' AS slug, '王维' AS title, '字摩诘。开元九年（721）进士擢第；安史陷两都时被贼所得，以凝碧诗获赦，官至尚书右丞。卒年旧唐书作乾元二年（759）、新唐书上元初（760–761）年六十一，两说并列。' AS summary, CAST(NULL AS SIGNED) AS start_year, CAST(NULL AS SIGNED) AS end_year, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'person-tang-li-shangyin' AS id, 'PERSON' AS entity_type, 'tang-li-shangyin' AS slug, '李商隐' AS title, '字义山，怀州河内人。开成二年（837）登进士第；晚年随郑亚在岭表，归后废罢还郑州，未几病卒（新唐书作客荥阳卒）。与温庭筠、段成式齐名，时号三十六体。' AS summary, CAST(NULL AS SIGNED) AS start_year, CAST(NULL AS SIGNED) AS end_year, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'person-tang-meng-haoran' AS id, 'PERSON' AS entity_type, 'tang-meng-haoran' AS slug, '孟浩然' AS title, '新唐书字浩然、襄州襄阳人。隐鹿门山，年四十游京师应进士不第；张九龄镇荆州署为从事。新唐书系其卒于开元末（713–741 之末），旧唐书只说不达而卒。' AS summary, CAST(NULL AS SIGNED) AS start_year, CAST(NULL AS SIGNED) AS end_year, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'person-tang-wang-changling' AS id, 'PERSON' AS entity_type, 'tang-wang-changling' AS slug, '王昌龄' AS title, '新唐书字少伯、江宁人。进士登第、又中博学宏词，再迁汜水尉；因不护细行屡见贬斥。卒因两史不同：旧唐书只说不达而卒，新唐书说还乡里后为刺史闾丘晓所杀。本传无可据年份，生卒留空。' AS summary, CAST(NULL AS SIGNED) AS start_year, CAST(NULL AS SIGNED) AS end_year, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'person-tang-cui-hao' AS id, 'PERSON' AS entity_type, 'tang-cui-hao' AS slug, '崔颢' AS title, '两史都说他登进士第、有文无行、好蒱博饮酒，终于司勋员外郎。旧唐书记天宝十三年（754）卒；两史都不记字。' AS summary, CAST(NULL AS SIGNED) AS start_year, CAST(NULL AS SIGNED) AS end_year, 'UNKNOWN' AS time_precision FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_content c WHERE c.id = t.id);

UPDATE poetry_content SET summary = '字子美，本襄阳人、后徙河南巩县。天宝初应进士不第，天宝十五载陷贼中奔灵武拜右拾遗。两史同记卒于耒阳、年五十九，但卒年一旧作永泰二年、一新作大历中，两说并列。'
 WHERE id = 'person-du-fu' AND summary = '待核查：生平、年谱与相关史料。' AND status <> 'PUBLISHED';

INSERT INTO poetry_person (id, dynasty_id, courtesy_name)
SELECT * FROM (
SELECT 'person-tang-li-bai' AS id, 'dynasty-tang' AS dynasty_id, '太白' AS courtesy_name FROM DUAL
UNION ALL
SELECT 'person-du-fu' AS id, 'dynasty-tang' AS dynasty_id, '子美' AS courtesy_name FROM DUAL
UNION ALL
SELECT 'person-tang-wang-wei' AS id, 'dynasty-tang' AS dynasty_id, '摩诘' AS courtesy_name FROM DUAL
UNION ALL
SELECT 'person-tang-li-shangyin' AS id, 'dynasty-tang' AS dynasty_id, '义山' AS courtesy_name FROM DUAL
UNION ALL
SELECT 'person-tang-meng-haoran' AS id, 'dynasty-tang' AS dynasty_id, '浩然' AS courtesy_name FROM DUAL
UNION ALL
SELECT 'person-tang-wang-changling' AS id, 'dynasty-tang' AS dynasty_id, '少伯' AS courtesy_name FROM DUAL
UNION ALL
SELECT 'person-tang-cui-hao' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS courtesy_name FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_person p WHERE p.id = t.id);

-- ---------- 生平属性断言（一条属性一条断言） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-person-tang-li-bai-courtesy.name' AS id, 'person-tang-li-bai' AS subject_id, 'courtesy.name' AS property_key, '太白' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-bai-origin' AS id, 'person-tang-li-bai' AS subject_id, 'origin' AS property_key, '兩說並列：舊唐書作「山東人」；新唐書說其先隋末以罪徙西域，神龍初遁還、客巴西（兩史都不記出生地）' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-bai-office' AS id, 'person-tang-li-bai' AS subject_id, 'office' AS property_key, '天寶初待詔翰林（天寶元載=742）' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-bai-life.event' AS id, 'person-tang-li-bai' AS subject_id, 'life.event' AS property_key, '安祿山反后转侧宿松、匡廬间；永王璘兵敗，坐長流夜郎' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-bai-death.place' AS id, 'person-tang-li-bai' AS subject_id, 'death.place' AS property_key, '兩說並列：舊唐書說醉死於宣城；新唐書說依當塗令李陽冰、死後葬於當塗東麓' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-bai-death.year' AS id, 'person-tang-li-bai' AS subject_id, 'death.year' AS property_key, '新唐書單源：代宗即位（寶應元載=762）時已卒，年六十餘；舊唐書不記年。年數只到「六十餘」，推不出確切生卒。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-du-fu-courtesy.name' AS id, 'person-du-fu' AS subject_id, 'courtesy.name' AS property_key, '子美' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-du-fu-origin' AS id, 'person-du-fu' AS subject_id, 'origin' AS property_key, '本襄陽人，後徙河南鞏縣' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-du-fu-jinshi' AS id, 'person-du-fu' AS subject_id, 'jinshi' AS property_key, '天寶初應進士不第；天寶末獻三大禮賦，召試文章，授京兆府兵曹参军（天寶末=751–756）' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-du-fu-life.event' AS id, 'person-du-fu' AS subject_id, 'life.event' AS property_key, '天寶十五載（=至德元載=756）祿山陷京師後，自京師宵遁赴河西謁肅宗於彭原郡，拜右拾遺' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-du-fu-office' AS id, 'person-du-fu' AS subject_id, 'office' AS property_key, '上元二年冬（=761）嚴武鎮成都，奏為節度叅謀檢校尚書工部員外郎' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-du-fu-death.place' AS id, 'person-du-fu' AS subject_id, 'death.place' AS property_key, '耒陽（兩史一致）' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-du-fu-death.year' AS id, 'person-du-fu' AS subject_id, 'death.year' AS property_key, '兩說並列：舊唐書作永泰二年（永泰二年即大曆元年=766）；新唐書只說「大曆中」（大曆=766–779）。兩史同記年五十九，但所記年份不同，不裁決。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-du-fu-burial' AS id, 'person-du-fu' AS subject_id, 'burial' AS property_key, '元和中年間，其孫嗣業自耒陽遷柩歸葬偃師縣西北首陽山之前' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-du-fu-fame' AS id, 'person-du-fu' AS subject_id, 'fame' AS property_key, '與李白齊名，時號李杜（兩史一致）' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-wei-courtesy.name' AS id, 'person-tang-wang-wei' AS subject_id, 'courtesy.name' AS property_key, '摩诘（两史一致）' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-wei-origin' AS id, 'person-tang-wang-wei' AS subject_id, 'origin' AS property_key, '太原祁人；父处廉终于汾州司马，徙家于蒲，遂为河东人' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-wei-jinshi' AS id, 'person-tang-wang-wei' AS subject_id, 'jinshi' AS property_key, '開元九年（=721）進士擢第；新唐書只作「開元初」（開元=713–741）' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-wei-life.event' AS id, 'person-tang-wang-wei' AS subject_id, 'life.event' AS property_key, '祿山陷兩都（至德元載=756）時扈從不及，為賊所得；後以凝碧池詩聞於行在，肅宗特宥之' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-wei-office' AS id, 'person-tang-wang-wei' AS subject_id, 'office' AS property_key, '官至尚書右丞（两史一致）' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-wei-death.year' AS id, 'person-tang-wang-wei' AS subject_id, 'death.year' AS property_key, '兩說並列：舊唐書作乾元二年（=759）七月卒；新唐書作上元初卒（上元=肅宗朝 760–761）、年六十一。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-wei-fame' AS id, 'person-tang-wang-wei' AS subject_id, 'fame' AS property_key, '詩名盛於開元、天寶間（两史一致）；舊唐書又記「維尤長五言詩」' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-shangyin-courtesy.name' AS id, 'person-tang-li-shangyin' AS subject_id, 'courtesy.name' AS property_key, '义山（两史一致）' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-shangyin-jinshi' AS id, 'person-tang-li-shangyin' AS subject_id, 'jinshi' AS property_key, '開成二年（=837）登進士第，释褐秘书省校书郎，调补弘农尉' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-shangyin-life.event' AS id, 'person-tang-li-shangyin' AS subject_id, 'life.event' AS property_key, '大中初（=847）令狐绹当国、共排李德裕，商隐随被贬的郑亚在岭表多年；大中末因柳仲郢得罪而废罢' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-shangyin-death.place' AS id, 'person-tang-li-shangyin' AS subject_id, 'death.place' AS property_key, '兩說並列：舊唐書作废罢后还郑州、未几病卒；新唐書作府罢后客荥阳卒。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-shangyin-fame' AS id, 'person-tang-li-shangyin' AS subject_id, 'fame' AS property_key, '与温庭筠、段成式齐名，时号三十六体（两史一致）' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-meng-haoran-courtesy.name' AS id, 'person-tang-meng-haoran' AS subject_id, 'courtesy.name' AS property_key, '浩然（新唐書單源；舊唐書本傳不記字）' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-meng-haoran-origin' AS id, 'person-tang-meng-haoran' AS subject_id, 'origin' AS property_key, '襄州襄陽人' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-meng-haoran-life.event' AS id, 'person-tang-meng-haoran' AS subject_id, 'life.event' AS property_key, '隱鹿門山；年四十來遊京師、應進士不第而還（两史一致）' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-meng-haoran-office' AS id, 'person-tang-meng-haoran' AS subject_id, 'office' AS property_key, '張九齡鎮荆州時署為從事，九齡府罷後無所進（两史一致；張九齡鎮荆州年代兩傳均未記，不推定）' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-meng-haoran-death.year' AS id, 'person-tang-meng-haoran' AS subject_id, 'death.year' AS property_key, '新唐書單源：開元末（開元=713–741）病疽背卒；舊唐書只說「不逹而卒」，無年。卒年不確定。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-changling-courtesy.name' AS id, 'person-tang-wang-changling' AS subject_id, 'courtesy.name' AS property_key, '少伯（新唐書單源；舊唐書本傳不記字）' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-changling-jinshi' AS id, 'person-tang-wang-changling' AS subject_id, 'jinshi' AS property_key, '進士登第，補秘書省校書郎；又以博學宏詞登科（两史一致）' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-changling-death.cause' AS id, 'person-tang-wang-changling' AS subject_id, 'death.cause' AS property_key, '兩說並列：舊唐書只說不護細行、屢見貶斥，卒（不記卒地卒因）；新唐書說以世亂還鄉里，為刺史閭丘曉所殺。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-changling-fame' AS id, 'person-tang-wang-changling' AS subject_id, 'fame' AS property_key, '為文緒微而思清（舊）／工詩，緒密而思清，時謂王江寧（新）' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-cui-hao-jinshi' AS id, 'person-tang-cui-hao' AS subject_id, 'jinshi' AS property_key, '登進士第（两史一致）' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-cui-hao-office' AS id, 'person-tang-cui-hao' AS subject_id, 'office' AS property_key, '官至司勳員外郎（两史一致）' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-cui-hao-death.year' AS id, 'person-tang-cui-hao' AS subject_id, 'death.year' AS property_key, '天寶十三年（=754）卒（舊唐書單源，新唐書不記年但不衝突）' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_claim c WHERE c.id = t.id);

INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'person-tang-li-bai' AS subject_id, 'courtesy.name' AS property_key, 'claim-person-tang-li-bai-courtesy.name' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-li-bai' AS subject_id, 'origin' AS property_key, 'claim-person-tang-li-bai-origin' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-li-bai' AS subject_id, 'office' AS property_key, 'claim-person-tang-li-bai-office' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-li-bai' AS subject_id, 'life.event' AS property_key, 'claim-person-tang-li-bai-life.event' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-li-bai' AS subject_id, 'death.place' AS property_key, 'claim-person-tang-li-bai-death.place' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-li-bai' AS subject_id, 'death.year' AS property_key, 'claim-person-tang-li-bai-death.year' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-du-fu' AS subject_id, 'courtesy.name' AS property_key, 'claim-person-du-fu-courtesy.name' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-du-fu' AS subject_id, 'origin' AS property_key, 'claim-person-du-fu-origin' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-du-fu' AS subject_id, 'jinshi' AS property_key, 'claim-person-du-fu-jinshi' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-du-fu' AS subject_id, 'life.event' AS property_key, 'claim-person-du-fu-life.event' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-du-fu' AS subject_id, 'office' AS property_key, 'claim-person-du-fu-office' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-du-fu' AS subject_id, 'death.place' AS property_key, 'claim-person-du-fu-death.place' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-du-fu' AS subject_id, 'death.year' AS property_key, 'claim-person-du-fu-death.year' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-du-fu' AS subject_id, 'burial' AS property_key, 'claim-person-du-fu-burial' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-du-fu' AS subject_id, 'fame' AS property_key, 'claim-person-du-fu-fame' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-wang-wei' AS subject_id, 'courtesy.name' AS property_key, 'claim-person-tang-wang-wei-courtesy.name' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-wang-wei' AS subject_id, 'origin' AS property_key, 'claim-person-tang-wang-wei-origin' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-wang-wei' AS subject_id, 'jinshi' AS property_key, 'claim-person-tang-wang-wei-jinshi' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-wang-wei' AS subject_id, 'life.event' AS property_key, 'claim-person-tang-wang-wei-life.event' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-wang-wei' AS subject_id, 'office' AS property_key, 'claim-person-tang-wang-wei-office' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-wang-wei' AS subject_id, 'death.year' AS property_key, 'claim-person-tang-wang-wei-death.year' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-wang-wei' AS subject_id, 'fame' AS property_key, 'claim-person-tang-wang-wei-fame' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-li-shangyin' AS subject_id, 'courtesy.name' AS property_key, 'claim-person-tang-li-shangyin-courtesy.name' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-li-shangyin' AS subject_id, 'jinshi' AS property_key, 'claim-person-tang-li-shangyin-jinshi' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-li-shangyin' AS subject_id, 'life.event' AS property_key, 'claim-person-tang-li-shangyin-life.event' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-li-shangyin' AS subject_id, 'death.place' AS property_key, 'claim-person-tang-li-shangyin-death.place' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-li-shangyin' AS subject_id, 'fame' AS property_key, 'claim-person-tang-li-shangyin-fame' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-meng-haoran' AS subject_id, 'courtesy.name' AS property_key, 'claim-person-tang-meng-haoran-courtesy.name' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-meng-haoran' AS subject_id, 'origin' AS property_key, 'claim-person-tang-meng-haoran-origin' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-meng-haoran' AS subject_id, 'life.event' AS property_key, 'claim-person-tang-meng-haoran-life.event' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-meng-haoran' AS subject_id, 'office' AS property_key, 'claim-person-tang-meng-haoran-office' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-meng-haoran' AS subject_id, 'death.year' AS property_key, 'claim-person-tang-meng-haoran-death.year' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-wang-changling' AS subject_id, 'courtesy.name' AS property_key, 'claim-person-tang-wang-changling-courtesy.name' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-wang-changling' AS subject_id, 'jinshi' AS property_key, 'claim-person-tang-wang-changling-jinshi' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-wang-changling' AS subject_id, 'death.cause' AS property_key, 'claim-person-tang-wang-changling-death.cause' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-wang-changling' AS subject_id, 'fame' AS property_key, 'claim-person-tang-wang-changling-fame' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-cui-hao' AS subject_id, 'jinshi' AS property_key, 'claim-person-tang-cui-hao-jinshi' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-cui-hao' AS subject_id, 'office' AS property_key, 'claim-person-tang-cui-hao-office' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-cui-hao' AS subject_id, 'death.year' AS property_key, 'claim-person-tang-cui-hao-death.year' AS claim_id FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection s WHERE s.subject_id = t.subject_id AND s.property_key = t.property_key);

-- ---------- citations：逐字史书原文 ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-person-tang-li-bai-courtesy.name' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·李白（文苑下）' AS locator, '李白字太白，山東人。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-bai-courtesy.name' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝中·新唐書卷二〇二·李白（文藝中）' AS locator, '李白，字太白，興聖皇帝九世孫。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-bai-origin' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·李白' AS locator, '李白字太白，山東人。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-bai-origin' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝中·新唐書卷二〇二·李白（神龍初=705，由年表換算）' AS locator, '其先隋末以罪徙西域，神龍初，遁還，客巴西。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-bai-office' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·李白（天寶初，天寶元載=742）' AS locator, '天寳初，客遊會稽，與道士吳筠隱於剡中。旣而玄宗詔筠赴京師，筠薦之於朝，遣使召之，與筠俱待詔翰林。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-bai-office' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝中·新唐書卷二〇二·李白' AS locator, '天寶初，南入會稽，與吳筠善，筠被召，故白亦至長安。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-bai-life.event' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝中·新唐書卷二〇二·李白（安祿山反=天寶十四載=755，與 tang-events 的安史之亂起點同年）；新唐書文藝中·新唐書卷二〇二·李白' AS locator, '安祿山反，轉側宿松、匡廬間，永王璘辟為府僚佐。……璘起兵，逃還彭澤，璘敗，當誅。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-bai-life.event' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·李白' AS locator, '永王謀亂，兵敗，白坐長流夜郎。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-bai-death.place' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·李白' AS locator, '後遇赦得還，竟以飲酒過度，醉死於宣城。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-bai-death.place' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝中·新唐書卷二〇二·李白；新唐書文藝中·新唐書卷二〇二·李白（青山在當塗）' AS locator, '李陽冰為當塗令，白依之。……白晚好黃老，度牛渚磯至姑孰，悅謝家青山，欲終焉。及卒，葬東麓。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-bai-death.year' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝中·新唐書卷二〇二·李白（代宗立=寶應元載=762，由年表換算）' AS locator, '代宗立，以左拾遺召，而白已卒，年六十餘。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-du-fu-courtesy.name' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·杜甫（文苑下）' AS locator, '杜甫，字子美，本襄陽人，後徙河南鞏縣。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-du-fu-origin' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·杜甫' AS locator, '杜甫，字子美，本襄陽人，後徙河南鞏縣。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-du-fu-jinshi' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·杜甫（天寶初，天寶元載=742）；舊唐書文苑下·舊唐書卷一九〇下·杜甫（「{{SKchar|2593}}宗」為录入缺字標記，指玄宗）' AS locator, '甫天寳初應進士不第。……天寳末，獻《三大禮賦》，{{SKchar|2593}}宗奇之，召試文章，授京兆府兵曹叅軍。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-du-fu-life.event' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·杜甫（十五載=天寶十五載=756，由年表換算；安史之亂起點同一年）' AS locator, '十五載，禄山䧟京師，肅宗徴兵靈武，甫自京師宵遁赴河西謁肅宗，於彭原郡拜右拾遺。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-du-fu-office' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·杜甫（上元二年=761，肅宗朝上元，由年表換算）' AS locator, '{{YL|上元二年}}冬，黄門侍郎、鄭國公嚴武鎮成都，奏為節度叅謀檢校尚書工部員外郎，賜緋魚袋。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-du-fu-death.place' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·杜甫' AS locator, '永泰二年，啗牛肉白酒，一夕而卒於耒陽，時年五十九。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-du-fu-death.place' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝上·新唐書卷二〇一·杜甫（文藝上；大曆元載=766，由年表換算）；新唐書文藝上·新唐書卷二〇一·杜甫' AS locator, '大曆中，出瞿唐，下江陵，溯沅、湘以登衡山，因客耒陽。……令嘗饋牛炙白酒，大醉，一昔卒，年五十九。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-du-fu-death.year' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·杜甫（永泰二年=大曆元年=766：代宗本紀「改永泰二年為大歷元年」，見本項目 tang-events 用舊唐書卷11引文）' AS locator, '永泰二年，啗牛肉白酒，一夕而卒於耒陽，時年五十九。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-du-fu-death.year' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝上·新唐書卷二〇一·杜甫（大曆=766–779，由年表換算）' AS locator, '大曆中，出瞿唐，下江陵，溯沅、湘以登衡山，因客耒陽。游岳祠，大水遽至，涉旬不得食，縣令具舟迎之，乃得還。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-du-fu-burial' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·杜甫（「元和中」=元和=806–820，由年表換算）' AS locator, '元和中，宗武子嗣業，自耒陽遷甫之柩，歸葬於偃師縣西北首陽山之前。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-du-fu-fame' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·杜甫' AS locator, '天寶末詩人，甫與李白齊名' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-du-fu-fame' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝上·新唐書卷二〇一·杜甫' AS locator, '少與李白齊名，時號「李杜」。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-wei-courtesy.name' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·王維（文苑下）' AS locator, '王維，字摩詰，太原祁人。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-wei-courtesy.name' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝中·新唐書卷二〇二·王維（文藝中）' AS locator, '王維，字摩詰。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-wei-origin' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·王維' AS locator, '王維，字摩詰，太原祁人。父處㢘，終汾州司馬，徙家于蒲，遂為河東人。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-wei-jinshi' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·王維（開元九年=721，由年表換算；{{YL|}}為录入標記）' AS locator, '維{{YL|開元九年}}進士擢第。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-wei-jinshi' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝中·新唐書卷二〇二·王維' AS locator, '開元初，擢進士，調太樂丞，坐累為濟州司倉參軍。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-wei-life.event' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·王維（陷兩都事在天寶末/至德間，756，由年表換算）；舊唐書文苑下·舊唐書卷一九〇下·王維' AS locator, '禄山䧟兩都，玄宗出幸，維扈從不及，為賊所得。……維以凝碧詩聞于行在，肅宗嘉之' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-wei-life.event' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝中·新唐書卷二〇二·王維' AS locator, '安祿山反，玄宗西狩，維為賊得，以藥下利，陽喑。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-wei-office' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·王維（乾元中至尚書右丞，乾元=758–759）' AS locator, '乾元中，遷太子中庶子、中書舍人，復拜給事中，轉尚書右丞。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-wei-office' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝中·新唐書卷二〇二·王維' AS locator, '久之，遷中庶子，三遷尚書右丞。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-wei-death.year' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·王維（乾元二年=759，由年表換算；{{YL|}}為录入標記）' AS locator, '{{YL|乾元二年}}七月卒。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-wei-death.year' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝中·新唐書卷二〇二·王維（上元=肅宗朝 760–761，由年表換算；另有高宗朝上元 674–675，此指肅宗）' AS locator, '上元初卒，年六十一。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-wei-fame' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·王維（開元=713–741，天寶=742–756）' AS locator, '維以詩名盛於開元、天寶間' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-wei-fame' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝中·新唐書卷二〇二·王維' AS locator, '維工草隸，善畫，名盛於開元、天寶間，豪英貴人虛左以迎，甯、薛諸王待若師友。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-shangyin-courtesy.name' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·李商隱（文苑下；此傳录入本用簡化字）' AS locator, '李商隐，字义山，怀州河内人。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-shangyin-courtesy.name' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝下·新唐書卷二〇三·李商隱（文藝下）' AS locator, '李商隱字義山，懷州河内人。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-shangyin-jinshi' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·李商隱（開成二年=837，由年表換算）' AS locator, '开成二年，方登进士第，释褐秘书省校书郎，调补弘农尉。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-shangyin-jinshi' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝下·新唐書卷二〇三·李商隱（開成二年=837）' AS locator, '調弘農尉，以活獄忤觀察使孫簡，將罷去，會姚合代簡，諭使還官。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-shangyin-life.event' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·李商隱（大中=847–859，由年表換算）' AS locator, '大中初，白敏中执政，令狐绹在内署，共排李德裕逐之。亚坐德裕党，亦贬循州刺史。商隐随亚在岭表累载。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-shangyin-life.event' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝下·新唐書卷二〇三·李商隱' AS locator, '亞謫循州，商隱從之，凡三年乃歸。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-shangyin-death.place' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·李商隱' AS locator, '会河南尹柳仲郢镇东蜀，辟为节度判官、检校工部郎中。大中末，仲郢坐专杀左迁，商隐废罢，还郑州，未几病卒。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-shangyin-death.place' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝下·新唐書卷二〇三·李商隱' AS locator, '府罷，客滎陽，卒。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-shangyin-fame' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·李商隱' AS locator, '与太原温庭筠、南郡段成式齐名，时号“三十六”。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-li-shangyin-fame' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝下·新唐書卷二〇三·李商隱' AS locator, '時温庭筠、段成式倶用是相夸，號「三十六體」。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-meng-haoran-courtesy.name' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝下·新唐書卷二〇三·孟浩然（文藝下）' AS locator, '孟浩然，字浩然，襄州襄陽人。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-meng-haoran-origin' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝下·新唐書卷二〇三·孟浩然' AS locator, '孟浩然，字浩然，襄州襄陽人。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-meng-haoran-life.event' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·孟浩然（文苑下）' AS locator, '孟浩然，隠鹿門山，以詩自適。年四十來遊京師，應進士不第，還。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-meng-haoran-life.event' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝下·新唐書卷二〇三·孟浩然（「-{}-」是录入本的繁简转换标记，引文原样保留）' AS locator, '少好節義，喜振人患難，隱鹿門山。年四十，乃-{游}-京師。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-meng-haoran-office' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·孟浩然' AS locator, '襄陽張九齡鎮荆州，署為從事，與之唱和，不逹而卒。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-meng-haoran-office' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝下·新唐書卷二〇三·孟浩然（「-{}-」是录入本的繁简转换标记，引文原样保留）' AS locator, '張九齡爲荊州，-{辟}-置-{於}-府，府罷。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-meng-haoran-death.year' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝下·新唐書卷二〇三·孟浩然（開元=713–741，由年表換算；「開元末」不記具体年）' AS locator, '開元末，病疽背卒。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-changling-courtesy.name' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝下·新唐書卷二〇三·王昌齡（文藝下，附孟浩然傳後）' AS locator, '昌齡，字少伯，江甯人。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-changling-jinshi' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·王昌齡（文苑下）' AS locator, '王昌齡者，進士登第，補秘書省，校書郎。又以博學宏詞登科，再遷汜水縣尉，不護細行，屢見貶斥，卒。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-changling-jinshi' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝下·新唐書卷二〇三·王昌齡' AS locator, '第進士，補秘書郎。又中宏辭，遷汜水尉。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-changling-death.cause' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·王昌齡' AS locator, '又以博學宏詞登科，再遷汜水縣尉，不護細行，屢見貶斥，卒。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-changling-death.cause' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝下·新唐書卷二〇三·王昌齡（「-{}-」是录入本的繁简转换标记，引文原样保留）' AS locator, '以世亂還鄕-{里}-，爲刺史閭丘曉所殺。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-changling-fame' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·王昌齡' AS locator, '昌齡為文緒微而思清，有集五卷。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-wang-changling-fame' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝下·新唐書卷二〇三·王昌齡（「-{}-」是录入本的繁简转换标记，引文原样保留）' AS locator, '昌齡工詩，緒密而思淸，時謂王江寧-{云}-。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-cui-hao-jinshi' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·崔顥（文苑下）' AS locator, '崔顥者，登進士第。有俊才無士行，好蒱博飲酒。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-cui-hao-jinshi' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝下·新唐書卷二〇三·崔顥（文藝下，附孟浩然傳後）' AS locator, '崔顥者，亦擢進士第，有文無行。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-cui-hao-office' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·崔顥' AS locator, '累官司勲員外郎。天寳十三年，卒。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-cui-hao-office' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝下·新唐書卷二〇三·崔顥' AS locator, '終司勳員外郎。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-cui-hao-death.year' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·崔顥（天寶十三年=754，由年表換算）' AS locator, '累官司勲員外郎。天寳十三年，卒。' AS evidence_excerpt FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_citation c WHERE c.claim_id = t.claim_id AND c.source_id = t.source_id);

-- ---------- 经历：诗人 × 阶段 A 已录事件 ----------
-- 年份留空（UNKNOWN）：本传只记此人经历其事，未记起止年；事件本身的年份在 V015 的 event 行上。
INSERT INTO poetry_content (id, entity_type, slug, title, summary, start_year, end_year, time_precision)
SELECT * FROM (
SELECT 'exp-tang-li-bai-anshi-rebellion' AS id, 'EXPERIENCE' AS entity_type, 'tang-li-bai-anshi-rebellion' AS slug, '李白·安祿山反，轉側宿松、匡廬…' AS title, '依据 李白 本传原文（新唐書文藝中）；本传未记起止年。' AS summary, CAST(NULL AS SIGNED) AS start_year, CAST(NULL AS SIGNED) AS end_year, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'exp-du-fu-anshi-rebellion' AS id, 'EXPERIENCE' AS entity_type, 'du-fu-anshi-rebellion' AS slug, '杜甫·十五載，禄山䧟京師，肅宗…' AS title, '依据 杜甫 本传原文（舊唐書文苑下）；本传未记起止年。' AS summary, CAST(NULL AS SIGNED) AS start_year, CAST(NULL AS SIGNED) AS end_year, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'exp-tang-wang-wei-anshi-rebellion' AS id, 'EXPERIENCE' AS entity_type, 'tang-wang-wei-anshi-rebellion' AS slug, '王维·禄山䧟兩都，玄宗出幸，維…' AS title, '依据 王维 本传原文（舊唐書文苑下）；本传未记起止年。' AS summary, CAST(NULL AS SIGNED) AS start_year, CAST(NULL AS SIGNED) AS end_year, 'UNKNOWN' AS time_precision FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_content c WHERE c.id = t.id);

INSERT INTO poetry_experience (id, person_id, event_id, place_id)
SELECT * FROM (
SELECT 'exp-tang-li-bai-anshi-rebellion' AS id, 'person-tang-li-bai' AS person_id, 'event-anshi-rebellion' AS event_id, CAST(NULL AS CHAR) AS place_id FROM DUAL
UNION ALL
SELECT 'exp-du-fu-anshi-rebellion' AS id, 'person-du-fu' AS person_id, 'event-anshi-rebellion' AS event_id, CAST(NULL AS CHAR) AS place_id FROM DUAL
UNION ALL
SELECT 'exp-tang-wang-wei-anshi-rebellion' AS id, 'person-tang-wang-wei' AS person_id, 'event-anshi-rebellion' AS event_id, CAST(NULL AS CHAR) AS place_id FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_experience e WHERE e.id = t.id);

INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-exp-tang-li-bai-anshi-rebellion-experience.event' AS id, 'exp-tang-li-bai-anshi-rebellion' AS subject_id, 'experience.event' AS property_key, 'event-anshi-rebellion' AS value_text, 'INTERPRETATION' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-exp-du-fu-anshi-rebellion-experience.event' AS id, 'exp-du-fu-anshi-rebellion' AS subject_id, 'experience.event' AS property_key, 'event-anshi-rebellion' AS value_text, 'INTERPRETATION' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-exp-tang-wang-wei-anshi-rebellion-experience.event' AS id, 'exp-tang-wang-wei-anshi-rebellion' AS subject_id, 'experience.event' AS property_key, 'event-anshi-rebellion' AS value_text, 'INTERPRETATION' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_claim c WHERE c.id = t.id);

INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'exp-tang-li-bai-anshi-rebellion' AS subject_id, 'experience.event' AS property_key, 'claim-exp-tang-li-bai-anshi-rebellion-experience.event' AS claim_id FROM DUAL
UNION ALL
SELECT 'exp-du-fu-anshi-rebellion' AS subject_id, 'experience.event' AS property_key, 'claim-exp-du-fu-anshi-rebellion-experience.event' AS claim_id FROM DUAL
UNION ALL
SELECT 'exp-tang-wang-wei-anshi-rebellion' AS subject_id, 'experience.event' AS property_key, 'claim-exp-tang-wang-wei-anshi-rebellion-experience.event' AS claim_id FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection s WHERE s.subject_id = t.subject_id AND s.property_key = t.property_key);

INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-exp-tang-li-bai-anshi-rebellion-experience.event' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝中·新唐書卷二〇二·李白（安祿山反=天寶十四載=755，與 tang-events 的安史之亂起點同年）（经历由此句读出）；新唐書文藝中·新唐書卷二〇二·李白（经历由此句读出）' AS locator, '安祿山反，轉側宿松、匡廬間，永王璘辟為府僚佐。……璘起兵，逃還彭澤，璘敗，當誅。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-exp-tang-li-bai-anshi-rebellion-experience.event' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·李白（经历由此句读出）' AS locator, '永王謀亂，兵敗，白坐長流夜郎。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-exp-du-fu-anshi-rebellion-experience.event' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·杜甫（十五載=天寶十五載=756，由年表換算；安史之亂起點同一年）（经历由此句读出）' AS locator, '十五載，禄山䧟京師，肅宗徴兵靈武，甫自京師宵遁赴河西謁肅宗，於彭原郡拜右拾遺。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-exp-tang-wang-wei-anshi-rebellion-experience.event' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書文苑下·舊唐書卷一九〇下·王維（陷兩都事在天寶末/至德間，756，由年表換算）（经历由此句读出）；舊唐書文苑下·舊唐書卷一九〇下·王維（经历由此句读出）' AS locator, '禄山䧟兩都，玄宗出幸，維扈從不及，為賊所得。……維以凝碧詩聞于行在，肅宗嘉之' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-exp-tang-wang-wei-anshi-rebellion-experience.event' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '新唐書文藝中·新唐書卷二〇二·王維（经历由此句读出）' AS locator, '安祿山反，玄宗西狩，維為賊得，以藥下利，陽喑。' AS evidence_excerpt FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_citation c WHERE c.claim_id = t.claim_id AND c.source_id = t.source_id);

-- ---------- coverage ----------
INSERT INTO poetry_coverage (id, entity_type, from_year, to_year, coverage_kind, status, note, updated_by, updated_at)
SELECT * FROM (
SELECT 'cov-person-tang-618-907' AS id, 'PERSON' AS entity_type, 618 AS from_year, 907 AS to_year, 'PARTIAL' AS coverage_kind, 'DRAFT' AS status, '唐诗三百首头部 7 位诗人已录入（合计 177 首／366 首），每条史实有旧唐书文苑或新唐书文艺的逐字原文；其余作者核到出处再补。生卒年两史不一致的一律不写。' AS note, 'chronology-emit' AS updated_by, NOW() AS updated_at FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_coverage c WHERE c.id = t.id);

INSERT INTO poetry_schema_version (version_no, description)
SELECT 16, 'Tang person biographies: 7 poets, 39 sourced attributes cited verbatim from Jiu Tangshu Wenyuan and Xin Tangshu Wenyi; birth/death years left UNKNOWN where the two histories disagree'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 16);
COMMIT;

