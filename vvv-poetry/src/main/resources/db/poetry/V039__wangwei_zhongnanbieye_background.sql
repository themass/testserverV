-- V039：王维《終南別業》(work-t300-135) 四层背景（阶段 D 第 20 首·八句 2/2/2/2 第二用）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V015、V016、V018 已执行（work-t300-135 与其 text-work-t300-135-ws、
--       source-ws-t300-135 是 V018 的行；source-jiutangshu-wenyuan / source-xintangshu-wenyi
--       是 V016 的行；source-quantangshi-126 是 V035 的行——均不另开）。
--       本迁移零新 source（断言）。
--
-- 数据源（可复现）：emit_v039.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/終南別業.txt（题目自注 {{*|一作…}} 与三处 {{另}} 标记原样——variants.md 先登记后照登）、
--   舊唐書卷190下（王维传奉佛段+卒段+辋川段——辋川段 V035 已立，别名侧再证声明入 locator）、
--   新唐書卷202（王维传奉佛段+卒段+辋川段——切片传区间归属生成时断言）。
--
-- 做：0 个新 source（断言）+ 4 BACKGROUND content/claim/background +
--   9 组逐字引用（(claim,source) 主键每对恰一行）+
--   8 行 background_line（八句形制：scene→1-2 city→3-4 world→5-6 person→7-8，
--   绑 text-work-t300-135-ws 的 8 行）。本迁移不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界与 V038 对偶成对）：
--   * 题=别名（別業=别宅）非地址，题目自注两题照登不裁决；
--   * 两传明记别业各唯一=蓝田辋川，零「終南別業」系事（负证逐字立出）；
--     「晚家南山陲」不指认蓝田别墅——两处宅子互不认领，两步读法不跨；
--   * 系年第十四次判决「题不系地，传不系年」→零铸造零 relation；
--   * KNOWN 两处：奉佛（旧「俱奉佛…不衣文綵」+新「篤志奉佛…衣不文彩」两源合龙）、
--     卒年存在性（旧「{{YL|乾元二年}}七月卒」+新「上元初卒，年六十一」相容并列，
--     改元细节不裁决）；均不外溢到诗；
--   * 鳏居条 V037 已判、诗名段 V035 已判——只引先例不重开（BG 与文件头双声明）；
--   * 跨迁移同句再证合规声明：JTS_WC/XTS_WC（V035 辋川线）此处别名侧再证。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 38，不含 39
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-zn-%';              -- 空
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-135-ws';  -- 恰 8（五律）
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-zn-%';        -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-135';                                  -- 8（每层两行）
--   SELECT certainty FROM poetry_claim WHERE id IN ('claim-bg-zn-world','claim-bg-zn-person');
--     -- KNOWN / KNOWN（world=奉佛两源；person=卒年两传直书）
--   SELECT certainty FROM poetry_claim WHERE id IN ('claim-bg-zn-scene','claim-bg-zn-city');
--     -- LIKELY / LIKELY
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-135'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-135';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-zn-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V039_rollback.sql（按 id 全枚举删除；不动 V018/V035 的行，不动共用来源行）
START TRANSACTION;

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-zn-scene' AS id, 'BACKGROUND' AS entity_type, 'zn-scene' AS slug, '眼前：走到水尽处坐下' AS title, '四层处境背景（阶段 D 第 20 首·八句 2/2/2/2 第二用）；史实句均有逐字引证；background_line 八句形制：每层两行（1-2/3-4/5-6/7-8）；系年第十四次判决「题不系地，传不系年」（与第十三次对偶）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 两处（奉佛两源合龙+卒年两传直书俱在）；鳏居 V037/诗名 V035 判例只引不重开；题目自注+四处 {{另}} 先登记后照登。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-zn-city' AS id, 'BACKGROUND' AS entity_type, 'zn-city' AS slug, '这座城：别名里的宅子' AS title, '四层处境背景（阶段 D 第 20 首·八句 2/2/2/2 第二用）；史实句均有逐字引证；background_line 八句形制：每层两行（1-2/3-4/5-6/7-8）；系年第十四次判决「题不系地，传不系年」（与第十三次对偶）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 两处（奉佛两源合龙+卒年两传直书俱在）；鳏居 V037/诗名 V035 判例只引不重开；题目自注+四处 {{另}} 先登记后照登。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-zn-world' AS id, 'BACKGROUND' AS entity_type, 'zn-world' AS slug, '这个天下：两唐书联署的素食' AS title, '四层处境背景（阶段 D 第 20 首·八句 2/2/2/2 第二用）；史实句均有逐字引证；background_line 八句形制：每层两行（1-2/3-4/5-6/7-8）；系年第十四次判决「题不系地，传不系年」（与第十三次对偶）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 两处（奉佛两源合龙+卒年两传直书俱在）；鳏居 V037/诗名 V035 判例只引不重开；题目自注+四处 {{另}} 先登记后照登。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-zn-person' AS id, 'BACKGROUND' AS entity_type, 'zn-person' AS slug, '这个人：最后一笔还是那条路' AS title, '四层处境背景（阶段 D 第 20 首·八句 2/2/2/2 第二用）；史实句均有逐字引证；background_line 八句形制：每层两行（1-2/3-4/5-6/7-8）；系年第十四次判决「题不系地，传不系年」（与第十三次对偶）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 两处（奉佛两源合龙+卒年两传直书俱在）；鳏居 V037/诗名 V035 判例只引不重开；题目自注+四处 {{另}} 先登记后照登。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-zn-scene' AS id, 'bg-zn-scene' AS subject_id, 'context' AS property_key, '前四句私人日志/后四句反纪年全诗本文（题目自注一作两题+四处 {{另}} 页内异文首读照登、variants.md 先登记）；「偶然」自拒系年为本层读法声明，非史料断言。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-zn-city' AS id, 'bg-zn-city' AS subject_id, 'context' AS property_key, '题=别名非地址（{{*}}自注两题照登）；两传明记别业各唯一=蓝田辋川（旧「得宋之問藍田别墅在輞口」/新「別墅在輞川」——V035 已立两源，此处别名侧再证）；传零系「終南別業」事（负证）；南山陲↔辋川两步读法不跨；题不系地、传不系年→零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-zn-world' AS id, 'bg-zn-world' AS subject_id, 'context' AS property_key, '王维兄弟终身奉佛两源独立一致：旧传「俱奉佛/蔬食/長齋/不衣文綵」+新传「篤志奉佛/食不葷/衣不文彩」要素两两相当各成句→升 KNOWN；奉佛起年两传零载不外推；「诗名盛于开元天宝间」V035 已判 KNOWN 不重复裁决；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-zn-person' AS id, 'bg-zn-person' AS subject_id, 'context' AS property_key, '卒年两传直书俱在（旧「{{YL|乾元二年}}七月卒」/新「上元初卒，年六十一」，相容并列不裁决改元细节）→存在性 KNOWN（V037 先例）；临终别书两传同幕（弟在凤翔/索笔作书）；鳏居条 V037 已判不重开；辋川宅与诗题別業互不认领为本层边界声明；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-zn-scene' AS subject_id, 'context' AS property_key, 'claim-bg-zn-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-zn-city' AS subject_id, 'context' AS property_key, 'claim-bg-zn-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-zn-world' AS subject_id, 'context' AS property_key, 'claim-bg-zn-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-zn-person' AS subject_id, 'context' AS property_key, 'claim-bg-zn-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-zn-scene' AS id, 'work-t300-135' AS work_id, 'SCENE' AS layer, '这首诗的前四句是一条完整的私人日志：「中歲頗好道，晚家南山陲」——中年起开始偏好那条路，晚年把家安到南山的边上；「興來每獨往，勝事{{另|空|祗}}自知」——兴头来了就一个人去，好处只有自己能知道（页内空/祗异读照登不裁决，V018 正文取首读「空」）。
后四句把这条日志写绝了：「行到水窮處，坐看雲起時」——走到水的尽头就坐下，看云起来；「偶然{{另|值|見}}{{另|林|鄰}}叟，談笑{{另|無|滯}}還期」——碰巧遇到个老人，谈笑之间就把回家的日子忘了（值/見、林/鄰、無/滯三对页内异读照登）。全诗没有一个事件——「偶然」两个字自己就是反纪年：这首诗拒绝被写进任何年谱。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-zn-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-zn-city' AS id, 'work-t300-135' AS work_id, 'CITY' AS layer, '「終南別業」是个**别名**不是地址：別業=别宅，题里只有「在終南那边有处宅子」的口气，没有可核之地；页上题目自注「一作初至山中，一作入山寄城中故人」——连诗题本身在两读之间（照登不裁决）。
而两传明记的那处别业在别处：旧传「得宋之問藍田别墅，在輞口，輞水周於舍下」，新传「別墅在輞川，地奇勝」——两传各有且只有一处宅子，都在蓝田辋川，传中无一字系「終南別業」之事。**不跨读**：辋川在蓝田、终南有支麓，两步读法能把「南山陲」挪去辋川——但那不是史料。「晚家南山陲」不指认蓝田别墅；两处宅子互不认领。题不系地，传不系年。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-zn-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-zn-world' AS id, 'work-t300-135' AS work_id, 'WORLD' AS layer, '「中歲頗好道」的自我报告，两唐书各有一句独立直书接住：
旧传「維弟兄俱奉佛，居常蔬食，不茹葷血，晚年長齋，不衣文綵」；新传「兄弟皆篤志奉佛，食不葷，衣不文彩」——措辞各自成句、要素两两相当（俱/皆奉佛、蔬食/食不葷、不衣文綵/衣不文彩）：**王维兄弟终身奉佛升 KNOWN**（两源独立一致）。
于是「好道」不再是可以打折的诗人套话——开天年间奉佛是上层士人的空气，两传把王维一家钉在这团空气里；但**具体哪一年开始蔬食长斋，两传不给**——中岁就是中岁。群像侧「诗名盛于開元、天寶間」两源亦俱在——V035 已判 KNOWN，此处不重复裁决只引先例。' AS body_text, 'SENIOR' AS audience, 'claim-bg-zn-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-zn-person' AS id, 'work-t300-135' AS work_id, 'PERSON' AS layer, '王维的死状两传直书俱在：旧传「{{YL|乾元二年}}七月卒。臨終之際，以縉在鳳翔，忽索筆作别縉書……捨筆而絶」；新传「上元初卒，年六十一。疾甚，縉在鳳翔，作書與別……停筆而化」——两源独立一致（乾元二年四月改元上元，七月与上元初相容；相容即并列，改元细节不裁决，V037 先例），「卒年两传俱在」升 KNOWN。两传同记的临终一幕更冷：弟弟王縉在凤翔行在，他索笔写别书——连告别都是公文的方向；遗书里「多敦厲朋友奉佛脩心之旨」，到最后一笔还是把朋友往那条路上推。
鳏居条（旧「妻亡不再娶」/新「喪妻不娶，孤居三十年」）V037 已两源合龙判过，本处不重开只声明。传中辋川宅与诗题別業互不认领——王维有几处宅子，史料说得清的只有一处，诗里这处说得清名字，说不清在哪。' AS body_text, 'SENIOR' AS audience, 'claim-bg-zn-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-zn-scene' AS claim_id, 'source-ws-t300-135' AS source_id, '页面 終南別業（header title 含题目自注 {{*}}+author 字段+八句全文，五段以「……」相連——四处 {{另}} 标记原样入证；V018 正文取首读，variants.md 已先登记；一句一对会把同一 (claim,source) 拆成八行违反主键——全文一行，V037 判例）' AS locator, '| title    = 終南別業{{*|一作初至山中，一作入山寄城中故人}}……| author   = 王維……中歲頗好道，晚家南山陲。……興來每獨往，勝事{{另|空|祗}}自知。……行到水窮處，坐看雲起時。……偶然{{另|值|見}}{{另|林|鄰}}叟，談笑{{另|無|滯}}還期。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-zn-city' AS claim_id, 'source-quantangshi-126' AS source_id, '卷一百二十六·王维诗目下本诗条目（锚点+转引用桩——卷页无正文，桩文照登；来源行 V035 已立，此处零新开）' AS locator, '==[[終南別業]]==
{{:終南別業}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-zn-city' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·王维传辋川段（旧传明记别业唯一=蓝田輞口，零「終南別業」系事之负证在此段；V035 已立此句（辋川线），此处别名侧再证——跨迁移同句再证，claim 不同故主键不冲突）' AS locator, '得宋之問藍田别墅，在輞口，輞水周於舍下，别漲竹洲花塢，與道友裴廸浮舟往來，彈琴賦詩，嘯詠終日。甞聚其田園所為詩，號輞川集。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-zn-city' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零二·文藝中·王维传辋川段（新传明记别墅唯一=輞川；V035 已立此句，此处别名侧再证）' AS locator, '別墅在輞川，地奇勝，有華子岡、欹湖、竹裏館、柳浪、茱萸沜、辛夷塢，與裴迪遊其中，賦詩相酬為樂。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-zn-world' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·王维传奉佛段（俱奉佛/蔬食/长斋/不衣文綵——两源合龙旧传侧逐字）' AS locator, '維弟兄俱奉佛，居常蔬食，不茹葷血，晚年長齋，不衣文綵。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-zn-world' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零二·文藝中·王维传奉佛段（笃志奉佛/食不葷/衣不文彩——两源合龙新传侧逐字）' AS locator, '兄弟皆篤志奉佛，食不葷，衣不文彩。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-zn-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·王维传卒段（乾元二年七月卒/临终别缙书/敦厉奉佛——直书旧传侧；{{YL|乾元二年}} 系快照年份链接模板标记，随文原样保留，非异文不入登记）' AS locator, '{{YL|乾元二年}}七月卒。臨終之際，以縉在鳳翔，忽索筆作别縉書，又與平生親故作别書數幅，多敦厲朋友奉佛脩心之旨，捨筆而絶。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-zn-person' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零二·文藝中·王维传卒段（上元初卒/年六十一/停筆而化——直书新传侧，相容并列）' AS locator, '上元初卒，年六十一。疾甚，縉在鳳翔，作書與別，又遺親故書數幅，停筆而化。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（八句：每层两行） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-zn-scene' AS background_id, 'text-work-t300-135-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-zn-scene' AS background_id, 'text-work-t300-135-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-zn-city' AS background_id, 'text-work-t300-135-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-zn-city' AS background_id, 'text-work-t300-135-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-zn-world' AS background_id, 'text-work-t300-135-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-zn-world' AS background_id, 'text-work-t300-135-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-zn-person' AS background_id, 'text-work-t300-135-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-zn-person' AS background_id, 'text-work-t300-135-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 39, 'Wang Wei Zhong-nan Bie-ye background layers (stage-D poem 20, 2/2/2/2 second use): dating verdict fourteen, the mirror pair of thirteen -- thirteen said the title carries the place while biographies record no such journey; here the reverse -- the title gives only an alias (bie-ye = a second house, no checkable site; the page carries two alternative titles under {{*}}, registered before quoting) and both biographies name exactly one estate each, both at Lan-tian Wang-chuan (JTS de Song zhi-wen Lan-tian bieshu zai Wang-kou + XTS bieshu zai Wang-chuan, both re-cited from V035 on the alias side -- cross-migration lawful, different claims), with zero lines tying the poem-title to any annalistic event -- the two houses never claim each other and the two-step reading that would move nan-shan chui onto the Wang river is refused: title pins no site, biographies pin no year, so time.span/event.name/written_during stay absent with zero relations; first KNOWN: the family devotion to Buddhism, JTS ju feng-fo / shu-shi / bu yi wen-cai plus XTS du-zhi feng-fo / shi bu hun / yi bu wen-cai -- two independent wordings, matching element by element; no year is inferred for the turn, zhong-sui stays zhong-sui; second KNOWN (existence-only): both biographies state his death outright (JTS Qian-yuan 2 7th month vs XTS Shang-yuan early, age 61) -- compatible, listed side by side, no ruling on the reign-name switch (V037 precedent); the widower line already KNOWN via V037 and the fame line already KNOWN via V035 are cited as precedents, not re-ruled; zero new sources (quan-tang-shi juan 126 opened by V035)'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 39);
COMMIT;
