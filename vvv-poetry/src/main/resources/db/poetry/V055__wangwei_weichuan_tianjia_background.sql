-- V055：王維《渭川田家》(work-t300-057) 四层背景（阶段 D 第 36 首·猎场与田家）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V014、V015、V016、V018、V035、V039、V054 已执行（work-t300-057 与其
--       text-work-t300-057-ws、source-ws-t300-057 是 V018 的行；source-quantangshi-125 是 V035 的行；
--       source-jiutangshu-wenyuan 是 V016 的行；source-zizhi-tongjian-events 是 V014/V015 已立的通鉴事件源）。
--       **本迁移零新 source**（audit 断言 SQL 无任何诗源表新建插入语句）。
--
-- 数据源（可复现）：emit_v055.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/渭川田家.txt（纯文本题异第三形态「川一作水」+四标记全零×75% 正交横截面）、
--   舊唐書卷190下（事母孝行句首引+王维段负证）、新唐書卷202（王维段负证）、
--   通鑑卷210（渭川唯一一处+開元元年窗口）+ 通鑑 75 卷/全唐詩 120 卷负证计数扫描+
--   既有迁移引文域逐句查重——传区间归属、渭川/渭水/田家/墟落/六诗语全部计数、
--   年标题窗口、首引前提与第二引前提全部生成时断言。
--
-- 做：4 BACKGROUND content/claim/background + 5 组逐字引用（(claim,source) 主键每对恰一行）+
--   10 行 background_line（十句形制：scene→1-4 city→5-6 world→7-8 person→9-10，
--   绑 text-work-t300-057-ws 的 10 行）。本迁移不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「題有河名，河在史部只一獵；詩有經意，經在史部全零」）：
--   * 渭川通鉴恰一处=皇家猎场（闭域+窗口断言）；诗语六词通鉴全零（诗牵着经史部不接）；
--   * 本诗正文第二引上限用满：V018 一引在先（全库查重恰一处），此诗正文对后来迁移关闭；
--   * 断词假命中两例在册零入引：tj-262「田家磑」地名+tj-257「故墟落」废墟语（闭域断言）；
--   * 完备度与标记数双向正交（V054 证 100% 可带标记、本页证零标记可不完备）；
--   * 纯文本题异第三形态「川一作水」照登硬卡（无标记挂底注，登记不裁决）；
--   * 旧传「事母崔氏以孝聞」首引（全库查重既往零引）；新传「資孝友」不并；
--   * 式微=邶风/两代人两种候均为读法声明，audit 双声明在 BG 文本内；
--   * KNOWN 零如实记录（第十一例，audit 反向断言 SQL 无 KNOWN 字面量）；
--   * 不才/凝碧/輞川/藍田/放田里/茶鐺/尤長五言/以詩名盛 判例只引不重开。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 54，不含 55
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-057-%';             -- 空
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-057-ws';  -- 恰 10
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-057-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-057';                                  -- 10（4/2/2/2）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-057-%';  -- 四行全 LIKELY（有意全 LIKELY）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-057'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-057';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-057-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
--   SELECT COUNT(*) FROM poetry_source WHERE id='source-ws-t300-057';   -- 恰 1（V018 旧行，零新源）
-- 回滚: recovery/V055_rollback.sql（按 id 全枚举删除；不动任何共用来源行、不动 V018 的行）
START TRANSACTION;

-- ---------- 1. BACKGROUND content identities（零新 source——断言在生成器 audit） ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-057-scene' AS id, 'BACKGROUND' AS entity_type, '057-scene' AS slug, '眼前：黄昏村口等门的人' AS title, '四层处境背景（阶段 D 第 36 首·十句五古 4/2/2/2）；史实句均有逐字引证；系年第三十次判决（题证系列第十八状·猎场与田家）「題有河名，河在史部只一獵；詩有經意，經在史部全零」——通鉴「渭川」75 卷恰一处=开元元年玄宗猎于渭川（闭域+年窗口断言），诗语六词（式微/雉雊/荊扉/牧童/斜陽/閑逸）通鉴全零——诗牵着经史部不接→time.span/event.name/written_during 全缺席、零 relation；纯文本题异第三形态首见（底注尾巴「川一作水」无标记挂底注，audit 照登硬卡）；完备度与标记数双向正交（V054 修正的横截面：零标记×75%）；本诗正文第二引上限用满对后来关闭（V018 在先+全库查重）；断词假命中两例在册零入引（tj-262 田家磑/tj-257 故墟落）；旧传「事母崔氏以孝聞」首引（全库查重既往零引）；KNOWN 零如实记录（第十一例，audit 反向断言）；零新 source；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-057-city' AS id, 'BACKGROUND' AS entity_type, '057-city' AS slug, '这座城：底注尾巴上的另一个题目' AS title, '四层处境背景（阶段 D 第 36 首·十句五古 4/2/2/2）；史实句均有逐字引证；系年第三十次判决（题证系列第十八状·猎场与田家）「題有河名，河在史部只一獵；詩有經意，經在史部全零」——通鉴「渭川」75 卷恰一处=开元元年玄宗猎于渭川（闭域+年窗口断言），诗语六词（式微/雉雊/荊扉/牧童/斜陽/閑逸）通鉴全零——诗牵着经史部不接→time.span/event.name/written_during 全缺席、零 relation；纯文本题异第三形态首见（底注尾巴「川一作水」无标记挂底注，audit 照登硬卡）；完备度与标记数双向正交（V054 修正的横截面：零标记×75%）；本诗正文第二引上限用满对后来关闭（V018 在先+全库查重）；断词假命中两例在册零入引（tj-262 田家磑/tj-257 故墟落）；旧传「事母崔氏以孝聞」首引（全库查重既往零引）；KNOWN 零如实记录（第十一例，audit 反向断言）；零新 source；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-057-world' AS id, 'BACKGROUND' AS entity_type, '057-world' AS slug, '这个天下：渭川在史部是皇帝的猎场' AS title, '四层处境背景（阶段 D 第 36 首·十句五古 4/2/2/2）；史实句均有逐字引证；系年第三十次判决（题证系列第十八状·猎场与田家）「題有河名，河在史部只一獵；詩有經意，經在史部全零」——通鉴「渭川」75 卷恰一处=开元元年玄宗猎于渭川（闭域+年窗口断言），诗语六词（式微/雉雊/荊扉/牧童/斜陽/閑逸）通鉴全零——诗牵着经史部不接→time.span/event.name/written_during 全缺席、零 relation；纯文本题异第三形态首见（底注尾巴「川一作水」无标记挂底注，audit 照登硬卡）；完备度与标记数双向正交（V054 修正的横截面：零标记×75%）；本诗正文第二引上限用满对后来关闭（V018 在先+全库查重）；断词假命中两例在册零入引（tj-262 田家磑/tj-257 故墟落）；旧传「事母崔氏以孝聞」首引（全库查重既往零引）；KNOWN 零如实记录（第十一例，audit 反向断言）；零新 source；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-057-person' AS id, 'BACKGROUND' AS entity_type, '057-person' AS slug, '这个人：事母以孝聞' AS title, '四层处境背景（阶段 D 第 36 首·十句五古 4/2/2/2）；史实句均有逐字引证；系年第三十次判决（题证系列第十八状·猎场与田家）「題有河名，河在史部只一獵；詩有經意，經在史部全零」——通鉴「渭川」75 卷恰一处=开元元年玄宗猎于渭川（闭域+年窗口断言），诗语六词（式微/雉雊/荊扉/牧童/斜陽/閑逸）通鉴全零——诗牵着经史部不接→time.span/event.name/written_during 全缺席、零 relation；纯文本题异第三形态首见（底注尾巴「川一作水」无标记挂底注，audit 照登硬卡）；完备度与标记数双向正交（V054 修正的横截面：零标记×75%）；本诗正文第二引上限用满对后来关闭（V018 在先+全库查重）；断词假命中两例在册零入引（tj-262 田家磑/tj-257 故墟落）；旧传「事母崔氏以孝聞」首引（全库查重既往零引）；KNOWN 零如实记录（第十一例，audit 反向断言）；零新 source；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-057-scene' AS id, 'bg-057-scene' AS subject_id, 'context' AS property_key, '十句全诗本文（ws 页四标记全零、Textquality 75%——零标记与不完备并存，正交横截面在册）；首联「斜陽照墟落，窮巷牛羊歸」系第二引：正文 V018 text claim 一引在先（生成时全库查重恰一处），两度上限至此用满、此诗正文对后来迁移关闭（audit 硬卡）；「式微=邶风篇名」及农事读法为本层声明非史料断言（页上无自注）。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-057-city' AS id, 'bg-057-city' AS subject_id, 'context' AS property_key, '纯文本题异第三形态：底注尾巴「川一作水」（渭川田家／渭水田家）无标记挂底注，逐字入引 audit 照登硬卡，登记不裁决；分类行照登+非史料声明+不升格；双向正交在册：V054 证 100% 可带标记、本页证零标记可不完备——标记与完备度绑定双侧证伪；卷125 无消歧锚+桩结构（机器断言各恰一）；诗世界渭川恰 6 处（本篇 2+他卷 4）在册不引；「渭水田家」全唐詩零命中；题有河而诗无时→零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-057-world' AS id, 'bg-057-world' AS subject_id, 'context' AS property_key, '一条河一件事：通鉴「渭川」恰 1 处=tj-210 开元元年（癸丑，七一三）玄宗「甲辰，獵於渭川」（文件闭域+年标题窗口机器断言）——史部的渭川是皇家猎场；诗语六词（式微/雉雊/荊扉/牧童/斜陽/閑逸）通鉴全零（机器断言）——诗牵着经，史部不接；断词假命中两例在册零入引（tj-262 田家磑地名恰 1、tj-257 故墟落废墟语恰 1，闭域断言）；渭水 6 处渡口战事在册不引；两传王维段渭川/田家/墟落全零；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-057-person' AS id, 'bg-057-person' AS subject_id, 'context' AS property_key, '旧传「事母崔氏以孝聞」首引（生成时全库引文域查重：既往零命中，audit 硬卡——王维传又一句未用活句，与 V053 传句用尽相反方向）；新传「資孝友」一支在册不并（两支各记各字，互证不合并）；两代人两种候为读法声明非史实；「放田里」V039 已引不再引；王维其余已用判例句零重开；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-057-scene' AS subject_id, 'context' AS property_key, 'claim-bg-057-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-057-city' AS subject_id, 'context' AS property_key, 'claim-bg-057-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-057-world' AS subject_id, 'context' AS property_key, 'claim-bg-057-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-057-person' AS subject_id, 'context' AS property_key, 'claim-bg-057-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-057-scene' AS id, 'work-t300-057' AS work_id, 'SCENE' AS layer, '十句是一幅黄昏村口的画：斜阳照进村落，牛羊走进深巷（「斜陽照墟落，窮巷牛羊歸」——此句系**第二引**：正文 V018 text claim 已一引在先，取此联收束本层，两度上限至此用满，此诗正文对后来迁移关闭）；村野老人惦记着牧童，拄着杖在柴门边等（「野老念牧童，倚杖候荊扉」——全诗唯一的人称情感落在「念」与「候」上）；野鸡叫了麦苗正秀，蚕已入眠桑叶渐稀，扛锄头的农人归来相见絮语不尽（「雉雊麥苗秀，蠶眠桑葉稀」「田夫荷鋤至，相見語依依」）。收束只一个转身：「即此羨閑逸，悵然吟式微」——「式微」是《詩經·邶風》篇名（「式微式微，胡不歸」），吟的是归去；此读法系本层声明非史料断言，页上无任何自注指认用典。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-057-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-057-city' AS id, 'work-t300-057' AS work_id, 'CITY' AS layer, '这条城记录的题目先登记异文：页底注整行为「{{Textquality|75%}}↑ [[全唐詩/卷125#渭川田家|全唐詩·卷125]]川一作水」——「渭川田家／渭水田家」两个题目挂在同一条底注尾巴上，**无 {{另}}/{{别}}/{{*}}/<ref> 任何标记**（纯文本题异第三形态：V052 纯文本署名异说、V053 <ref> 实链+又見底注之后，audit 硬卡「川一作水」字样），照登不裁决。分类行「五言古詩」为整理者动作：照登+非史料声明+不升格（V048 判例）。**完备度与标记数的双向正交在册（V054 修正的横截面）**：本页四标记全零而 Textquality 只有 75%——V054 已证 100% 可带五枚标记，本页再证零标记不等于已录完备；「标记↔完备度」任何一侧的绑定都不成立，如实登记。卷125 本篇为「无消歧篇题锚点+转引桩」结构（机器断言锚+桩各恰一）。诗世界的渭川：全唐詩「渭川」恰 6 处——本卷 2 处即本篇锚桩，余四处（卷017 李賀、卷021、卷581、卷695）各是各诗，在册不引不牵合；「渭水田家」全唐詩零命中（异文支在册不引）。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-057-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-057-world' AS id, 'work-t300-057' AS work_id, 'WORLD' AS layer, '诗的题面有一条河；史部这条河只记过一件事：通鉴「渭川」75 卷**恰一处**（文件闭域+年标题窗口机器断言）——开元元年（癸丑，七一三）「甲辰，獵於渭川」，紧接「上欲以同州刺史姚元之為相」：天子在渭川打猎、顺手拜相。**渭川在史部是皇帝的猎场**。
诗里满纸《詩經》——式微是邶风篇名、雉雊语出小弁、牛羊來下是王风意象（读法声明）；而通鉴「式微」「雉雊」「荊扉」「牧童」「斜陽」「閑逸」**六个词全部零命中**（机器断言）——**诗牵着经，史部不接**。
断词假命中两例在册零入引（V054 之后的例行复查）：通鉴「田家」恰 1=天复元年（辛酉，九零一）李茂貞迎车驾于「田家磑」（地名）、「墟落」恰 1=光启三年赵全義招怀流散于「故墟落」中（废墟语）——都不是这首诗；渭水通鉴 6 处全是渡口战事，在册不引。
两传王维段「渭川」「田家」「墟落」全零（机器断言）——传写其人不提这条川。**猎场与田家同一条水，各是各的世界**；本层零铸造零 relation。' AS body_text, 'SENIOR' AS audience, 'claim-bg-057-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-057-person' AS id, 'work-t300-057' AS work_id, 'PERSON' AS layer, '旧传给这个人记了一行孝：「**事母崔氏以孝聞**。」——奉养母亲崔氏以孝行闻名（生成时全库查重：此句既往零入引，本迁移 PERSON 层首引；新传同只一句「資孝友」——两支各记各字，互证不合并）。
把孝行和诗对读：传里的孝是对母亲的，诗里最重的一笔是野老候童孙「倚杖候荊扉」——**两代人两种候**（读法声明，非史实）。
王维传其余已用句（以诗名盛/凝碧/輞川别业/茶鐺/奉佛段/代宗诏集/尤長五言/書畫特臻其妙/妻亡不再娶/臨終别縉书）一个不重开；新传自表五短「願歸所任官，放田里」V039 已引在册不再引——「放田里」三个字恰与「羨閑逸」同一片田地，但那是表里的话、已入账，本迁移零新引；certainty 不覆盖任何系年。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-057-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-057-scene' AS claim_id, 'source-ws-t300-057' AS source_id, '页面 渭川田家（header author+五联十句，四段以「……」相連——「斜陽照墟落，窮巷牛羊歸」**第二引**：正文 V018 text claim 一引在先、本迁移取首联二引，**两度上限至此用满，此诗正文对后来迁移关闭**（生成时全库查重恰一处=V018）；页四标记全零、75%（零标记与不完备并存）；「吟式微」页上无自注，归《詩經》读法系引者声明非史料）' AS locator, '| author   = 王維……斜陽照墟落，窮巷牛羊歸。
野老念牧童，倚杖候荊扉。……雉雊麥苗秀，蠶眠桑葉稀。
田夫荷鋤至，相見語依依。……即此羨閑逸，悵然吟式微。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-057-city' AS claim_id, 'source-ws-t300-057' AS source_id, '页面 渭川田家（header title+页底注+分类行三段并收——底注尾巴「川一作水」系**纯文本题异第三形态**（渭川/渭水两题并挂无标记，audit 硬卡字样照登不裁决）；「五言古詩」分类系整理者动作：非史料声明、不升格；本页零标记而 75%——与 V054（100% 带五标记）互为横截面，完备度与标记数双向正交在册）' AS locator, '| title    = 渭川田家……| notes    = {{Textquality|75%}}↑ [[全唐詩/卷125#渭川田家|全唐詩·卷125]]川一作水……[[Category:五言古詩]]' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-057-city' AS claim_id, 'source-quantangshi-125' AS source_id, '卷一百二十五·王维集《渭川田家》篇题锚点+转引桩（无消歧直锚——篇题在全唐詩快照内唯一故不消歧，机器断言锚桩各恰一；全唐詩「渭川」恰 6=本篇 2+他卷 4 处题族在册不引）' AS locator, '==[[渭川田家]]==……{{:渭川田家}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-057-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷二百一十·开元元年（癸丑，七一三）玄宗猎于渭川段（**通鉴 75 卷「渭川」唯一一处**：文件闭域+年标题窗口机器断言，紧接上欲相姚元之——史部的渭川是皇家猎场；诗语六词通鉴全零在册；tj-262 田家磑/tj-257 故墟落两例断词假命中闭域在册零入引）' AS locator, '甲辰，獵於渭川。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-057-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·王维传事母孝行句（生成时全库引文域查重：此句既往零入引，本迁移首引；新传「資孝友」一支互证不合并；与诗中野老候门并置是读法声明）' AS locator, '事母崔氏以孝聞。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（十句：4/2/2/2） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-057-scene' AS background_id, 'text-work-t300-057-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-057-scene' AS background_id, 'text-work-t300-057-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-057-scene' AS background_id, 'text-work-t300-057-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-057-scene' AS background_id, 'text-work-t300-057-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-057-city' AS background_id, 'text-work-t300-057-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-057-city' AS background_id, 'text-work-t300-057-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-057-world' AS background_id, 'text-work-t300-057-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-057-world' AS background_id, 'text-work-t300-057-ws' AS version_id, 8 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-057-person' AS background_id, 'text-work-t300-057-ws' AS version_id, 9 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-057-person' AS background_id, 'text-work-t300-057-ws' AS version_id, 10 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 55, 'Wang Wei on a Farm by the Wei River background layers (stage-D poem 36, ten-line old-style verse 4/2/2/2, second such shape after V051): dating verdict thirty, eighteenth shape of the title-evidence series -- the title names a river and the river owns exactly one entry in the official history (all 75 Tongjian juan machine-swept: one hit, juan 210, the emperor hunting on the Wei in 713 right before enfeoffing Yao Yuanzhi as chancellor: in history this river is an imperial hunting ground), while the poem leans on the Book of Songs (shi wei is a beifeng title) and six of its words (shiwei/zhi gou/jing fei/mu tong/xie yang/xian yi) score zero across the whole Tongjian -- the poem holds the classics and the histories do not answer; dating verdict: a title with a river, a river with one hunt; a poem with the Odes, the Odes absent from history -- zero forging, zero relation; third plain-text title-variant form registered: the footnote tail "chuan yi zuo shui" (Wei-chuan/Wei-shui hanging off a plain footnote with no marker at all, audit hard-assert, unadjudicated); completeness orthogonal to marker count in both directions now on record (this page: zero markers yet only 75%, the cross-section of V054''s 100%-with-five-markers correction); the poem body reaches its two-use ceiling (V018 first citation machine-swept, this migration cites the first couplet as second use, locator declares closure); two cut-word false hits logged never quoted (Tianjia-mill as a place name in juan 262, gu xuluo as ruin-words in juan 257, file-closed assertions); the Old History''s filial sentence on serving his mother Lady Cui first-cited (sweep proves zero prior hits), the New History''s single word on filial nature kept unmerged; KNOWN zero honestly recorded (eleventh instance, audit reverse-asserts); zero new sources; closed precedent keywords stay out of citations'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 55);
COMMIT;
