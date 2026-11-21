-- V020：《月夜》(work-t300-207) 四层背景 + 系年 + 安史线挂接（阶段 D 第 2 首）。MySQL 5.6.40 兼容。
-- 只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V003（background 有 body_text）、V004（Audience 词表先例）、V011、V015、V017、V018 已执行
--       —— background_line 绑到 text-work-t300-207-ws，那一行是 V018 插的；缺 V018 本迁移的行会成孤儿。
--
-- 数据源（可复现）：引文由 emit_v020.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，
--   与快照逐字节一致（杜詩詳註四庫本卷四·月夜注条；通鉴217/218/222 与两唐书·杜甫传切片与 V019 共用同一代码路径）。
--   {{SK anchor|}}、{{SK notes|}} 等录入标记照登。
--
-- 做：4 个 BACKGROUND content/claim/background（正文全部带证）+ 14 行逐字引用 + 8 行 background_line
--   （scene→1,2｜city→3,4｜person→5,6｜world→7,8，绑 text-work-t300-207-ws）
--   + 系年断言 claim-yueye-time-756（鹤注单源 → LIKELY）+ written_during 安史之乱挂接（形状同 V017 春望）。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布；不写 review_log；
--   不裁决两《唐书》「为贼所得 vs 宵遁」矛盾——PERSON 层 claim 保持 DISPUTED，两边证据都挂上。
--
-- 诚实边界：
--   * 两《唐书》对杜甫如何陷长安的记载矛盾（新唐书：為賊所得／旧唐书：宵遁赴行在），正文言明、不取独断；
--   * 系年只有鹤注单源（天寳十五載八月），LIKELY 而非 KNOWN，更不是「定论」；
--   * 「家人对月」是诗的想象结构（杜臆语），不是杜甫目击的事实，正文照此写。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;       -- 含 19，不含 20
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-yueye-%';               -- 空
--   SELECT id FROM poetry_text_version WHERE id='text-work-t300-207-ws';    -- 恰 1 行（V018 已执行）
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-yueye-%';         -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-207';                                      -- 8
--   SELECT certainty FROM poetry_claim WHERE id='claim-bg-yueye-person';    -- DISPUTED（两唐书矛盾未裁）
-- 回滚: recovery/V020_rollback.sql（按 id 全枚举反序删除；不动 V018 的任何行）
START TRANSACTION;

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-yueye-scene' AS id, 'BACKGROUND' AS entity_type, 'yueye-scene' AS slug, '眼前：想象里家人的月亮' AS title, '四层处境背景（阶段 D 第 2 首）；史实句均有逐字引证，分歧与单源均已在正文言明。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-yueye-city' AS id, 'BACKGROUND' AS entity_type, 'yueye-city' AS slug, '这座城：陷落的长安' AS title, '四层处境背景（阶段 D 第 2 首）；史实句均有逐字引证，分歧与单源均已在正文言明。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-yueye-world' AS id, 'BACKGROUND' AS entity_type, 'yueye-world' AS slug, '这个天下：打了八年才收京的战事' AS title, '四层处境背景（阶段 D 第 2 首）；史实句均有逐字引证，分歧与单源均已在正文言明。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-yueye-person' AS id, 'BACKGROUND' AS entity_type, 'yueye-person' AS slug, '这个人：身陷长安、家寄鄜州' AS title, '四层处境背景（阶段 D 第 2 首）；史实句均有逐字引证，分歧与单源均已在正文言明。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语是 BACKGROUND content 行，同 V004 的形状：claim id 与 subject id 是两个东西） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-yueye-scene' AS id, 'bg-yueye-scene' AS subject_id, 'context' AS property_key, '对面写法（本思家而写家人思己）为注家《杜臆》指出的读法；想象之月是诗的结构，不是诗人目击。' AS value_text, 'INTERPRETATION' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-yueye-city' AS id, 'bg-yueye-city' AS subject_id, 'context' AS property_key, '长安沦陷后的搜捕与秩序崩坏有《资治通鉴》卷218逐字记载；本诗背景中的陷城处境另系于鹤注系年（756）。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-yueye-world' AS id, 'bg-yueye-world' AS subject_id, 'context' AS property_key, '战事起讫以通鉴年标题为锚（755反于范阳/763史朝义死）；本诗系年于天宝十五载八月（=756）出自鹤注单源，LIKELY。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-yueye-person' AS id, 'bg-yueye-person' AS subject_id, 'context' AS property_key, '家眷在鄜州、身在贼占长安为鹤注与新唐书一致；「如何陷在长安」两《唐书》矛盾（新唐书：为贼所得／旧唐书：宵遁赴行在拜右拾遗），不裁决。' AS value_text, 'FACT' AS claim_kind, 'DISPUTED' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-yueye-scene' AS subject_id, 'context' AS property_key, 'claim-bg-yueye-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-yueye-city' AS subject_id, 'context' AS property_key, 'claim-bg-yueye-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-yueye-world' AS subject_id, 'context' AS property_key, 'claim-bg-yueye-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-yueye-person' AS subject_id, 'context' AS property_key, 'claim-bg-yueye-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows（一层一段正文；audience 是遗留编写元数据，读者端不用） ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-yueye-scene' AS id, 'work-t300-207' AS work_id, 'SCENE' AS layer, '这首诗的「眼前」不在诗人自己面前：他被困在长安，看见的月亮是想象里家人的月亮——今夜鄜州上空那轮月，只有妻子一个人在看。
「本是自己思家，偏从对面写家人想你」不是现代人的讲法：注本《杜臆》就说「公本思家偏想家人思已，已进一层；至念及儿女不能思，又进一层」。先把自己翻过去，再替家人把月看完——这一层的入口是注家早就指出的。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-yueye-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-yueye-city' AS id, 'work-t300-207' AS work_id, 'CITY' AS layer, '「未解忆长安」——孩子们还不懂得「长安」两个字值多少牵挂。懂的人才知道：这座京城已经陷在叛军手里，诗人自己也陷在里面。
沦陷后的长安，《资治通鉴》卷二一八记了两笔：禄山「命搜捕百官、宦者、宫女等，每获数百人，辄以兵卫送洛阳」，留在长安的王侯将相「诛及婴孩」；同罗、突厥叛军逃归时「长安大扰，官吏窜匿，狱囚自出」。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-yueye-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-yueye-world' AS id, 'work-t300-207' AS work_id, 'WORLD' AS layer, '这场战事起于天宝十四年（乙未，公元七五五年）「禄山发所部兵……反于范阳」，终于广德元年（癸卯，公元七六三年）史朝义「穷蹙，缢于林中」——都在《资治通鉴》的年标题里。
这首诗写于乱中的哪一年？注家给了一个点：仇注引鹤注系于天宝十五载八月，也就是公元 756 年。这是单源注本的系年，我们记下它，不把它当定论。' AS body_text, 'SENIOR' AS audience, 'claim-bg-yueye-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-yueye-person' AS id, 'work-t300-207' AS work_id, 'PERSON' AS layer, '写这首诗时，杜甫的家眷寄在鄜州，他本人在沦陷的长安——「身在长安，家在鄜州」。
他是怎么陷在长安的，两部正史自己就先打架：《新唐书》本传说他「自鄜州羸服欲奔行在，为贼所得」（衣衫破旧想去投奔朝廷，半路被叛军抓住）；《旧唐书》本传却说「十五载，禄山陷京师……甫自京师宵遁赴河西，谒肃宗于彭原郡，拜右拾遗」（夜里逃出去了）。两说并存，我们不下判断；《月夜》的处境读法依据的是《新唐书》与鹤注「为贼所得，时在长安」这一边。
注家说这首诗「笃于伉俪」：刘后村引陈伯霆的玩笑反证——人们都说杜甫善谑、连妻女都不放过，可「香雾云鬟湿，清辉玉臂寒」写妻子的发肤如此细致，「其笃于伉俪如此」。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-yueye-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文 ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-yueye-scene' AS claim_id, 'source-dushi-xiangzhu' AS source_id, '卷四·月夜·杜臆语（{{SK anchor|}}、{{SK notes|}} 为四库本录入标记，照登）' AS locator, '杜臆公本思家偏想家人思已已進一層至念及兒女不能思又進一層鬟濕臂寒看月之久也月愈好而苦愈增語麗情悲末又想到聚首時對月舒愁之狀詞旨婉切見此老鍾情之至' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yueye-city' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '通鑑卷二百十八·唐紀三十四（至德元載=756，由年表換算）；搜捕句與大擾句以「……」相連' AS locator, '祿山命搜捕百官、宦者、宮女等，每獲數百人，輒以兵衛送洛陽。王、侯、將、相扈從車駕、家留長安者，誅及嬰孩。……同羅、突厥之逃歸也，長安大擾，官吏竄匿，獄囚自出。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yueye-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '通鑑卷二百十七起點＋卷二百二十二終點（年標題與紀事句以「……」相連；卷217內年標題作「天寶十四年」不作「載」，照登）' AS locator, '玄宗至道大聖大明孝皇帝下之下天寶十四年（乙未，公元七五五年）……十一月，甲子，祿山發所部兵及同羅、奚、契丹、室韋凡十五萬眾，號二十萬，反於范陽。……肅宗文明武德大聖大宣孝皇帝下之下廣德元年（癸卯，公元七六三年）……朝義窮蹙，縊於林中，懷仙取其首以獻。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yueye-world' AS claim_id, 'source-dushi-xiangzhu' AS source_id, '卷四·月夜·鶴注（天寳十五載八月=756，由年表換算；單源注本係年）' AS locator, '{{SK anchor|月夜}}{{SK notes|鶴注天寳十五載八月公自鄜州赴行在為賊所得時身在長安家在鄜州故作此詩}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yueye-person' AS claim_id, 'source-dufu-zhuan-candidate' AS source_id, '卷二百一·文藝上·杜甫传（新唐书说：被执一边）' AS locator, '時所在寇奪，甫家寓鄜，彌年艱窶，孺弱至餓死；肅宗立，自鄜州羸服欲奔行在，為賊所得' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yueye-person' AS claim_id, 'source-jiutangshu-dufu' AS source_id, '卷一百九十下·杜甫传（旧唐书说：宵遁一边——与新唐书矛盾，两说并存的另一半证据）' AS locator, '十五載，禄山䧟京師，肅宗徴兵靈武，甫自京師宵遁赴河西謁肅宗，於彭原郡拜右拾遺' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yueye-person' AS claim_id, 'source-dushi-xiangzhu' AS source_id, '卷四·月夜·鶴注＋劉後村語（「身在長安家在鄜州」注本依据；伉俪之篤的注家读法；两段以「……」相連）' AS locator, '{{SK anchor|月夜}}{{SK notes|鶴注天寳十五載八月公自鄜州赴行在為賊所得時身在長安家在鄜州故作此詩}}……劉後村詩話故人陳伯霆讀北征詩戲云子美善謔如粉黛忽解包狼籍畫睂濶雖妻女亦不恕余云公知其一耳如月夜詩云香霧雲鬟濕清暉玉臂寒則閨中之髮膚雲濃玉潔可見又云何時倚虚幌雙照淚痕乾其篤於伉儷如此' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（绑 V018 的版本；行号 1–8 都在） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-yueye-scene' AS background_id, 'text-work-t300-207-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-yueye-scene' AS background_id, 'text-work-t300-207-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-yueye-city' AS background_id, 'text-work-t300-207-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-yueye-city' AS background_id, 'text-work-t300-207-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-yueye-person' AS background_id, 'text-work-t300-207-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-yueye-person' AS background_id, 'text-work-t300-207-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-yueye-world' AS background_id, 'text-work-t300-207-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-yueye-world' AS background_id, 'text-work-t300-207-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 系年断言（鹤注单源 → LIKELY；758 式第二说：月夜没有，但单源不给 KNOWN） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-yueye-time-756' AS id, 'work-t300-207' AS subject_id, 'time.span' AS property_key, '756..756 (EXACT) 鹤注：天宝十五载八月，自鄜州赴行在为贼所得时在长安（单源注本，换算：天宝十五载=756）' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'work-t300-207' AS subject_id, 'time.span' AS property_key, 'claim-yueye-time-756' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT 'claim-yueye-time-756', 'source-dushi-xiangzhu',
       '卷四·月夜·鶴注（天寳十五載八月=756，由年表換算；單源注本係年，故 LIKELY 不升 KNOWN）',
       '{{SK anchor|月夜}}{{SK notes|鶴注天寳十五載八月公自鄜州赴行在為賊所得時身在長安家在鄜州故作此詩}}'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_citation
  WHERE claim_id = 'claim-yueye-time-756' AND source_id = 'source-dushi-xiangzhu');

-- ---------- 7. written_during 安史之乱（形状同 V017 春望；claim 主语=work） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-yueye-in-anshi' AS id, 'work-t300-207' AS subject_id, 'event.name' AS property_key, '安史之亂（755–763）。鶴注係年天寶十五載（756）落在亂期內；「憶長安」與陷城語境為詩內證' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'work-t300-207' AS subject_id, 'event.name' AS property_key, 'claim-yueye-in-anshi' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-yueye-in-anshi' AS claim_id, 'source-dushi-xiangzhu' AS source_id, '卷四·月夜·鶴注（係年756在亂期內）' AS locator, '{{SK anchor|月夜}}{{SK notes|鶴注天寳十五載八月公自鄜州赴行在為賊所得時身在長安家在鄜州故作此詩}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-yueye-in-anshi' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '通鑑卷二百十七·天寶十四年（乙未，公元七五五年）年標題（亂世起点；「……」連反于范陽句）' AS locator, '玄宗至道大聖大明孝皇帝下之下天寶十四年（乙未，公元七五五年）……十一月，甲子，祿山發所部兵及同羅、奚、契丹、室韋凡十五萬眾，號二十萬，反於范陽。' AS evidence_excerpt FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);
INSERT INTO poetry_relation (id, subject_id, predicate, object_id, claim_id)
SELECT * FROM (
SELECT 'rel-work-t300-207-written-during-anshi' AS id, 'work-t300-207' AS subject_id, 'written_during' AS predicate, 'event-anshi-rebellion' AS object_id, 'claim-yueye-in-anshi' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_relation x WHERE x.id = t.id OR (x.subject_id = t.subject_id AND x.predicate = t.predicate AND x.object_id = t.object_id));

-- ---------- 8. 版本账本 ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 20, 'yue-ye background layers (sourced, inserts-only): 4 bg + lines on text-work-t300-207-ws, 756 dating (single-source LIKELY), written_during anshi; Jiu/Xin Tangshu capture contradiction kept DISPUTED'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 20);
COMMIT;
