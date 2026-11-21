-- V038：孟浩然《宿建德江》(work-t300-122) 四层背景（阶段 D 第 19 首·绝句第三例）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V015、V016、V018 已执行（work-t300-122 与其 text-work-t300-122-ws、
--       source-ws-t300-122 是 V018 的行；source-jiutangshu-wenyuan / source-xintangshu-wenyi
--       是 V016 的行——不另开行）。本迁移零新 source（全唐詩卷160 已由 V031 开立——
--       孟集本身已是已立来源，宿建德江即在其中，不重复引卷页桩，正文在诗页）。
--
-- 数据源（可复现）：emit_v038.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/宿建德江.txt（第1句含 {{另|煙|幽}} 标记原样——variants.md 先登记后照登）、
--   舊唐書卷190下（孟传首句+文苑类序总评「皆名位不振」句——后者不在孟传段内，
--   生成器断言其位置在孟传段之前，类序体例已在 locator 声明）、
--   新唐書卷203（孟传鹿门段+韩朝宗约荐段+段末「皆位不顯」+孟亭段；
--   切片传区间归属生成时断言；V031 已用切片零重叠）。
--
-- 做：0 个新 source（断言）+ 4 BACKGROUND content/claim/background +
--   7 组逐字引用（(claim,source) 主键每对恰一行）+
--   4 行 background_line（**绝句形制：每层一行** scene→1 city→2 world→3 person→4，
--   绑 text-work-t300-122-ws 的 4 行）。本迁移不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「题证地方不证时间」）：
--   * 建德=题内直载；两传行迹零吴越记载（负证逐字立出）——漫游吴越常识不补史料；
--   * 系年第十三次判决：地方有、年月无→零铸造零 relation；
--   * KNOWN 两处：隐鹿门山（旧「隠鹿門山」+新「隱鹿門山」两源合龙）、
--     位不显群像鉴定（旧类序总评+新传段末，两源独立一致）；均不外溢到诗；
--   * 孟亭/浩然亭身后纪念新传单源不升；韩朝宗荐举起点单得 LIKELY（爽约后续 V031 已立）；
--   * 死状两传分歧（不达而卒/病疽背卒）V031 已并列——本迁移不重复裁决并声明；
--   * JTS_NAME 句 V031 已立（交游侧），此处群像侧再证——跨迁移同句再证合规声明。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 37，不含 38
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-jd-%';              -- 空
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-122-ws';  -- 恰 4（绝句）
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-jd-%';        -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-122';                                  -- 4（绝句每层一行）
--   SELECT certainty FROM poetry_claim WHERE id IN ('claim-bg-jd-world','claim-bg-jd-person');
--     -- KNOWN / KNOWN（world=位不显两源；person=隐鹿门两源）
--   SELECT certainty FROM poetry_claim WHERE id IN ('claim-bg-jd-scene','claim-bg-jd-city');
--     -- LIKELY / LIKELY
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-122'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-122';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-jd-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V038_rollback.sql（按 id 全枚举删除；不动 V018/V031 的行，不动共用来源行）
START TRANSACTION;

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-jd-scene' AS id, 'BACKGROUND' AS entity_type, 'jd-scene' AS slug, '眼前：一条船的夜' AS title, '四层处境背景（阶段 D 第 19 首·绝句第三例）；史实句均有逐字引证；background_line 绝句形制：每层一行（1/2/3/4）；系年第十三次判决「题自带地名，传不纪其游」→time.span/event.name/written_during 全缺席、零 relation；KNOWN 三处之两处（隐鹿门两源+位不显群像两源），孟亭单源不升；{{另|煙|幽}} 先登记后照登。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-jd-city' AS id, 'BACKGROUND' AS entity_type, 'jd-city' AS slug, '这座城：题里有地名，传里没有路' AS title, '四层处境背景（阶段 D 第 19 首·绝句第三例）；史实句均有逐字引证；background_line 绝句形制：每层一行（1/2/3/4）；系年第十三次判决「题自带地名，传不纪其游」→time.span/event.name/written_during 全缺席、零 relation；KNOWN 三处之两处（隐鹿门两源+位不显群像两源），孟亭单源不升；{{另|煙|幽}} 先登记后照登。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-jd-world' AS id, 'BACKGROUND' AS entity_type, 'jd-world' AS slug, '这个天下：一代人的位不显' AS title, '四层处境背景（阶段 D 第 19 首·绝句第三例）；史实句均有逐字引证；background_line 绝句形制：每层一行（1/2/3/4）；系年第十三次判决「题自带地名，传不纪其游」→time.span/event.name/written_during 全缺席、零 relation；KNOWN 三处之两处（隐鹿门两源+位不显群像两源），孟亭单源不升；{{另|煙|幽}} 先登记后照登。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-jd-person' AS id, 'BACKGROUND' AS entity_type, 'jd-person' AS slug, '这个人：鹿门的两个写法' AS title, '四层处境背景（阶段 D 第 19 首·绝句第三例）；史实句均有逐字引证；background_line 绝句形制：每层一行（1/2/3/4）；系年第十三次判决「题自带地名，传不纪其游」→time.span/event.name/written_during 全缺席、零 relation；KNOWN 三处之两处（隐鹿门两源+位不显群像两源），孟亭单源不升；{{另|煙|幽}} 先登记后照登。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-jd-scene' AS id, 'bg-jd-scene' AS subject_id, 'context' AS property_key, '移舟/泊渚/日暮/野旷/江清/月近全诗本文（{{另|煙|幽}} 页内异文首读煙照登，variants.md 先登记）；愁有名目与否——两传无一字拴住此夜，愁只有浓度没有名目。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-jd-city' AS id, 'bg-jd-city' AS subject_id, 'context' AS property_key, '地点=题内直载（建德，桐江上——行政归属为常识注，非本证）；江行实景与桐江相合为读法声明；两传行迹零吴越记载——题证地方不证时间；漫游吴越常识不补史料。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-jd-world' AS id, 'bg-jd-world' AS subject_id, 'context' AS property_key, '「知名而位不显」群像鉴定两源独立一致：旧传类序总评「皆名位不振」（含孟/王/崔/高四人名，唯高适达）与新传孟传段末「皆位不顯」（王/崔同知名者）各自逐字——鉴定结论本身升 KNOWN；不外溢到诗：客愁≠鉴定文书，诗 time.span/event.name/written_during 零铸造、零 relation。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-jd-person' AS id, 'bg-jd-person' AS subject_id, 'context' AS property_key, 'KNOWN 一处：隐鹿门山——旧传「隠鹿門山」与新传「隱鹿門山」两源合龙（以诗自适/侠气各单传色彩 LIKELY）；身后孟亭/浩然亭纪念新传单源不升；韩朝宗荐举起点段新传单得 LIKELY（爽约后续 V031 已立）；死状两传分歧 V031 已并列，本处不重复裁决；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-jd-scene' AS subject_id, 'context' AS property_key, 'claim-bg-jd-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-jd-city' AS subject_id, 'context' AS property_key, 'claim-bg-jd-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-jd-world' AS subject_id, 'context' AS property_key, 'claim-bg-jd-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-jd-person' AS subject_id, 'context' AS property_key, 'claim-bg-jd-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-jd-scene' AS id, 'work-t300-122' AS work_id, 'SCENE' AS layer, '这一晚的船泊在渚边：「移舟泊{{另|煙|幽}}渚，日暮客愁新」——把船挪开水流靠住小洲，天黑了，客愁是新的（V018 正文取首读「煙渚」；页内「幽渚」异读照登不裁决）。夜里的景只有两组：「野曠天低樹」——原野太空，天压到树顶；「江清月近人」——江水太清，月亮凑到船边来。天地挤到一条船上，只剩月亮站在客人这一边。
愁什么，两传给不了这场夜：新传给过一打具体的愁（太学赋诗四座叹伏之后是放还、爽约、府罢），但没有一条拴住这一晚。愁有浓度，没有名目。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-jd-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-jd-city' AS id, 'work-t300-122' AS work_id, 'CITY' AS layer, '这是阶段 D 十九首里**地名最硬的一首**：题目直接落在建德——桐江上的县，严子陵钓台所在地，唐属睦州。诗里「江清」「野曠」与桐江江行实景相合（读法，非史料断言）。
但传里的地图到此为止：旧传三行行迹——鹿门山、京师、荆州；新传添上太学、内署、韩朝宗相约的京师。两传**无一字记吴越之游**。题证地方，不证时间：这首诗确实在建德（题），却不在任何一条史料行迹线上，也没有年月。漫游吴越是后世常识，常识不补史料——time.span/event.name/written_during 一个都不造。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-jd-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-jd-world' AS id, 'work-t300-122' AS work_id, 'WORLD' AS layer, '「客愁」的愁，两唐书各给了一份群像鉴定，两源的结论惊人一致：
旧唐书文苑类卷末总评：「開元、天寳間，文士知名者，汴州崔顥，京兆王昌齡、高適，㐮陽孟浩然，**皆名位不振**，唯高適官逹，自有傳」——注意这句不在孟传里，在邻传传末，是类序式的总评（旧书体例如此，逐字照录）；新唐书孟传段末：「開元、天寶間，同知名者王昌齡、崔顥，**皆位不顯**」。
两源独立一致：孟浩然—王昌龄—崔颢这一批「知名而位不显」是两唐书共同的鉴定结论——升 KNOWN。「日暮客愁新」于是有了社会学的浓度：不是一个人怀才不遇，是一代人；月近人因为没有人。' AS body_text, 'SENIOR' AS audience, 'claim-bg-jd-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-jd-person' AS id, 'work-t300-122' AS work_id, 'PERSON' AS layer, '孟浩然的身份底片两源合龙：旧传「孟浩然，隠鹿門山，以詩自適」，新传「少好節義，喜振人患難，隱鹿門山」——**隐鹿门山**三个字的两个独立写法，升 KNOWN；以诗自适（旧）与侠气好施（新）各为单传色彩，照登。
新传留了两段旧传没有的：其一，采访使韩朝宗约他同入京师「欲薦諸朝」（本迁移取事件起点句；剧饮爽约的后续 V031 已引，不重复）——推荐人自己先辞了行，是另一重「位不顯」的制度形状；其二，身后纪念：「王維過郢州，畫浩然像于刺史亭，因曰浩然亭」，咸通中刺史郑諴嫌直呼贤者名讳不敬，改名**孟亭**——新传单源，不升 KNOWN，但王维画像素（V035/V037 王维线）与这条孟亭记载在同一传里互证：两人相识这件事本身，新传「張九齡、王維雅稱道之」句另有直证。
死状两条线（旧「不达而卒」/新「病疽背卒」）V031 已并列不裁决，本首不重复。' AS body_text, 'SENIOR' AS audience, 'claim-bg-jd-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-jd-scene' AS claim_id, 'source-ws-t300-122' AS source_id, '页面 宿建德江（header title+author 两字段+第1、2句，四段以「……」相連——第1句含页内异文标记 {{另|煙|幽}} 原样入证（V018 正文取首读煙渚，variants.md 已先登记）；全文另见 V018 claim-t300-122-text 引文）' AS locator, '| title    = 宿建德江……| author   = 孟浩然……移舟泊{{另|煙|幽}}渚，……移舟泊{{另|煙|幽}}渚，日暮客愁新。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-jd-city' AS claim_id, 'source-ws-t300-122' AS source_id, '页面 宿建德江（第3、4句逐字——野旷江清：题外地名的唯一诗内实景）' AS locator, '野曠天低樹，……野曠天低樹，江清月近人。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-jd-city' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·孟浩然传（旧传行迹全部三行：鹿門山—京師—荊州——零吴越记载之负证在本段；与 V037 所引 JTS_MH/JTS_MH2 相接不重叠）' AS locator, '孟浩然，隠鹿門山，以詩自適。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-jd-world' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·类序总评（陆据传末「皆名位不振」句——**不在孟传段内**，旧书文苑类序体例；V031 已引此句为孟氏交游证，此处群像侧再证——跨迁移同句再证，claim 不同故主键不冲突）' AS locator, '開元、天寳間，文士知名者，汴州崔顥，京兆王昌齡、高適，㐮陽孟浩然，皆名位不振，唯高適官逹，自有傳。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-jd-world' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零三·文藝中·孟浩然传段末（「同知名者王昌齡、崔顥，皆位不顯」——群像鉴定新传侧；与旧传总评两源独立一致）' AS locator, '開元、天寶間，同知名者王昌齡、崔顥，皆位不顯。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-jd-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·孟浩然传首句（隠鹿門山/以詩自適——两源合龙旧传侧；与 CITY 层同句异claim各立一行）' AS locator, '孟浩然，隠鹿門山，以詩自適。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-jd-person' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零三·文藝中·孟浩然传（鹿门段+韩朝宗约荐段+孟亭段；三段以「……」相連，同卷同传——鹿门两源合龙新传侧/荐举起点单得/身后纪念单源不升）' AS locator, '少好節義，喜振人患難，隱鹿門山。……採訪使韓朝宗約浩然偕至京師，欲-{薦}-諸朝。……初，王維過郢州，畫浩然像-{于}-刺史亭，因曰浩然亭。-{咸}-通中，刺史鄭諴謂賢者名不可斥，更署曰孟亭。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（绝句：每层一行） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-jd-scene' AS background_id, 'text-work-t300-122-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-jd-city' AS background_id, 'text-work-t300-122-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-jd-world' AS background_id, 'text-work-t300-122-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-jd-person' AS background_id, 'text-work-t300-122-ws' AS version_id, 4 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 38, 'Meng Haoran Su Jian-de-jiang background layers (stage-D poem 19, third quatrain): dating verdict thirteen in a new pairing -- the title nails the PLACE (Jian-de on the Tong river, directly stated in the title) while both histories record no Wu-Yue journey at all (negative evidence quoted line by line: JTS itineraries are Lu-men mountain / the capital / Jing-zhou only) -- title proves where, never when; wandering south of the Yangtze is later common knowledge and common knowledge does not backfill sources, so time.span/event.name/written_during remain absent with zero relations; the new-sad-of-the-traveler (ri-ri mu ke-chou xin) gets a sociological dose from two independent group verdicts: the JTS class-序 remark (placed at the end of a neighbouring biography, a class-order convention, generator-asserted outside the Meng bio block, already cited by V031 on the friendship side and re-cited here on the cohort side -- cross-migration re-citation of one sentence under different claims is lawful) listing Cui Hao, Wang Chang-ling, Gao Shi, Meng Haoran as all holding low positions, and the XTS closing line of Meng-s biography saying the same of Wang and Cui -- KNOWN for the cohort verdict, never overflowing to the poem; second KNOWN: the Lu-men mountain reclusion, JTS yin Lu-men shan plus XTS yin Lu-men shan in two independent wordings; a Meng-ting commemoration note (Wang Wei painted his portrait; the pavilion renamed under Xian-tong) is XTS-only and stays LIKELY; the two death accounts divergence already registered by V031 stays un-ruled and is declared as such here; zero new sources (quan-tang-shi juan 160 opened by V031 -- Meng-s collected poems are already a sourced shelf, poem text lives on the ws page); the page-internal variant yan/you registered in variants.md before quoting'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 38);
COMMIT;
