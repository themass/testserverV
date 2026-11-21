-- V062：王維《酬張少府》(work-t300-063) 四层背景（阶段 D 第 43 首·官名与长策解带）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V014、V015、V016、V018、V035、V039、V040、V044、V052、V054、V059、V060、V061 已执行
--       （work-t300-063 与其 text-work-t300-063-ws、source-ws-t300-063 是 V018 的行；
--       source-quantangshi-126 是 V035/V039/V052/V054/V060 已立的卷126 源行（本迁移第六次复用，零新源）；
--       source-xintangshu-wenyi 是 V016 的行；source-zizhi-tongjian-events 是 V014/V015 已立的通鉴事件源；
--       判例在册句长斋（V039）/焚香（V044）/願歸所任官（V040）/召缙（V061）只引不重开）。
--       本迁移零新 source（audit 断言无诗源表新建插入语句）。
--
-- 数据源（可复现）：emit_v062.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/酬張少府.txt（{{另}}×1×75%+底注全锚+三百首标记在页）、
--   舊唐書卷190下/新唐書卷202（两传全文靜字全零负证+議者不之罪首引+願歸所任官零重开）、
--   全唐詩卷126（裸名锚+桩）/卷218/卷511/卷524/卷525（好静/解带/渔歌在册句闭域）、
--   通鑑卷193/235/256（長策恰七+解帶恰二+四处年标题窗口）+ 通鑑 75 卷/全唐詩 118 卷
--   存快照负证计数扫描（張少府/少府/少府監/少府少監/長策/解帶/窮通/舊林/松風/漁歌/
--   山月/好靜/不關心/空知/浦深/酬答）+
--   既有迁移引文域逐句查重——传区间归属、首引/二引/零重开前提全部生成时断言。
--
-- 做：4 BACKGROUND content/claim/background + 5 组逐字引用（(claim,source) 主键每对恰一行）+
--   8 background_line（八句五律 **2/2/2/2 第四次**（V054/V058/V060）：scene→1-2 city→3-4
--   world→5-6 person→7-8，绑 text-work-t300-063-ws 的 8 行）+ 零 poetry_source 行 + 不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「題有官名，官名在史部只為監署；詩有長策解帶，長策在史部只經國是，
--   解帶在史部只急變須臾」）：
--   * 張少府/窮通/舊林/松風/漁歌/山月/好靜通鉴全零+少府恰十二只监署（闭域+构成断言）；
--   * 長策恰七+解帶恰二闭域；国是双句+急变双句共四句史文入引为判决证据（audit 硬卡）；
--   * 不答是答与四字考语不置可否均标明读法声明非史实（页上无自注）；
--   * 异文君/若引文含标记原样；同页两形并存三度再验（V018 归一形 vs 本迁移原样形）；
--   * 三种消歧形态齐备照登（V059 作者/V061 首句/本篇裸名——消歧器有无即同名登记）；
--   * 此诗正文第二引上限用满：V018 一引在先（双针查重各恰一处），对后来迁移关闭；
--   * vol218/511/524/525 他卷在册句零入引（audit 硬卡零混入）；
--   * KNOWN 零如实记录（第十八例，audit 反向断言 SQL 无 KNOWN 字面量）；
--   * 願歸所任官（V040）/召缙句（V061）/长斋（V039）/焚香（V044）判例只引不重开。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 61，不含 62
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-063-%';             -- 空
--   SELECT id FROM poetry_source WHERE id='source-quantangshi-126';     -- 恰 1（五迁移已立，本迁移复用不新建）
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-063-ws';  -- 恰 8
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-063-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-063';                                  -- 8（2/2/2/2）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-063-%';  -- 四行全 LIKELY（有意全 LIKELY）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-063'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-063';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-063-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
--   SELECT COUNT(*) FROM poetry_source WHERE id='source-quantangshi-126';  -- 恰 1（复用，非本迁移所立）
-- 回滚: recovery/V062_rollback.sql（按 id 全枚举删除；零 source 删除——卷126 源行为五迁移所立）
START TRANSACTION;

-- ---------- 1. 零新 source（卷126 源行五迁移已立，本迁移第六次复用） ----------
-- ---------- 2. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-063-scene' AS id, 'BACKGROUND' AS entity_type, '063-scene' AS slug, '眼前：晚年只爱清静的自述' AS title, '四层处境背景（阶段 D 第 43 首·八句五律 2/2/2/2 第四次）；史实句均有逐字引证；系年第三十七次判决（题证系列第廿五状·官名与长策解带）「題有官名，官名在史部只為監署；詩有長策解帶，長策在史部只經國是，解帶在史部只急變須臾」——通鉴「張少府」全零、少府恰十二（监署七+少府少監四+机构一，闭域+构成断言）；長策恰七闭域（国是双句入引：安邊之長策貞觀四年庚寅六三〇+聚斂為長策貞元十年甲戌七九四）；解帶恰二闭域全引（脫巾解帶跪而固諫貞觀五年辛卯六三一+解帶繫頸而乘之光啟二年丙午八八六）——同字两界第七形态·一首诗双对首见·急閑异位（史最急/诗最闲，audit 双向硬卡）；窮通/舊林通鉴+全唐詩双双全零（诗的问答在两界之外）；漁歌全唐詩恰二在册零入引+好靜恰一（杜甫句）在册不牵合；三种消歧形态至此齐备（V059 作者/V061 首句/本篇裸名——消歧器有无本身即同名登记）；卷126 恰二闭域+底注全锚；零新源（卷126 源 V035/V039/V052/V054/V060 已立第六次复用）；{{另}}×1×75% 正交第六度+同页两形并存三度再验；此诗正文第二引上限用满第十例对后来关闭（V018 在先+双针查重）；PERSON 首引新传「議者不之罪」（願歸所任官 V040 零重开；两传全文靜字全零——诗面字不进传第二例）；KNOWN 零如实记录（第十八例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-063-city' AS id, 'BACKGROUND' AS entity_type, '063-city' AS slug, '这座城：不需要消歧器的篇题' AS title, '四层处境背景（阶段 D 第 43 首·八句五律 2/2/2/2 第四次）；史实句均有逐字引证；系年第三十七次判决（题证系列第廿五状·官名与长策解带）「題有官名，官名在史部只為監署；詩有長策解帶，長策在史部只經國是，解帶在史部只急變須臾」——通鉴「張少府」全零、少府恰十二（监署七+少府少監四+机构一，闭域+构成断言）；長策恰七闭域（国是双句入引：安邊之長策貞觀四年庚寅六三〇+聚斂為長策貞元十年甲戌七九四）；解帶恰二闭域全引（脫巾解帶跪而固諫貞觀五年辛卯六三一+解帶繫頸而乘之光啟二年丙午八八六）——同字两界第七形态·一首诗双对首见·急閑异位（史最急/诗最闲，audit 双向硬卡）；窮通/舊林通鉴+全唐詩双双全零（诗的问答在两界之外）；漁歌全唐詩恰二在册零入引+好靜恰一（杜甫句）在册不牵合；三种消歧形态至此齐备（V059 作者/V061 首句/本篇裸名——消歧器有无本身即同名登记）；卷126 恰二闭域+底注全锚；零新源（卷126 源 V035/V039/V052/V054/V060 已立第六次复用）；{{另}}×1×75% 正交第六度+同页两形并存三度再验；此诗正文第二引上限用满第十例对后来关闭（V018 在先+双针查重）；PERSON 首引新传「議者不之罪」（願歸所任官 V040 零重开；两传全文靜字全零——诗面字不进传第二例）；KNOWN 零如实记录（第十八例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-063-world' AS id, 'BACKGROUND' AS entity_type, '063-world' AS slug, '这个天下：史的解带最急，诗的解带最闲' AS title, '四层处境背景（阶段 D 第 43 首·八句五律 2/2/2/2 第四次）；史实句均有逐字引证；系年第三十七次判决（题证系列第廿五状·官名与长策解带）「題有官名，官名在史部只為監署；詩有長策解帶，長策在史部只經國是，解帶在史部只急變須臾」——通鉴「張少府」全零、少府恰十二（监署七+少府少監四+机构一，闭域+构成断言）；長策恰七闭域（国是双句入引：安邊之長策貞觀四年庚寅六三〇+聚斂為長策貞元十年甲戌七九四）；解帶恰二闭域全引（脫巾解帶跪而固諫貞觀五年辛卯六三一+解帶繫頸而乘之光啟二年丙午八八六）——同字两界第七形态·一首诗双对首见·急閑异位（史最急/诗最闲，audit 双向硬卡）；窮通/舊林通鉴+全唐詩双双全零（诗的问答在两界之外）；漁歌全唐詩恰二在册零入引+好靜恰一（杜甫句）在册不牵合；三种消歧形态至此齐备（V059 作者/V061 首句/本篇裸名——消歧器有无本身即同名登记）；卷126 恰二闭域+底注全锚；零新源（卷126 源 V035/V039/V052/V054/V060 已立第六次复用）；{{另}}×1×75% 正交第六度+同页两形并存三度再验；此诗正文第二引上限用满第十例对后来关闭（V018 在先+双针查重）；PERSON 首引新传「議者不之罪」（願歸所任官 V040 零重开；两传全文靜字全零——诗面字不进传第二例）；KNOWN 零如实记录（第十八例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-063-person' AS id, 'BACKGROUND' AS entity_type, '063-person' AS slug, '这个人：两传全文一个静字没有' AS title, '四层处境背景（阶段 D 第 43 首·八句五律 2/2/2/2 第四次）；史实句均有逐字引证；系年第三十七次判决（题证系列第廿五状·官名与长策解带）「題有官名，官名在史部只為監署；詩有長策解帶，長策在史部只經國是，解帶在史部只急變須臾」——通鉴「張少府」全零、少府恰十二（监署七+少府少監四+机构一，闭域+构成断言）；長策恰七闭域（国是双句入引：安邊之長策貞觀四年庚寅六三〇+聚斂為長策貞元十年甲戌七九四）；解帶恰二闭域全引（脫巾解帶跪而固諫貞觀五年辛卯六三一+解帶繫頸而乘之光啟二年丙午八八六）——同字两界第七形态·一首诗双对首见·急閑异位（史最急/诗最闲，audit 双向硬卡）；窮通/舊林通鉴+全唐詩双双全零（诗的问答在两界之外）；漁歌全唐詩恰二在册零入引+好靜恰一（杜甫句）在册不牵合；三种消歧形态至此齐备（V059 作者/V061 首句/本篇裸名——消歧器有无本身即同名登记）；卷126 恰二闭域+底注全锚；零新源（卷126 源 V035/V039/V052/V054/V060 已立第六次复用）；{{另}}×1×75% 正交第六度+同页两形并存三度再验；此诗正文第二引上限用满第十例对后来关闭（V018 在先+双针查重）；PERSON 首引新传「議者不之罪」（願歸所任官 V040 零重开；两传全文靜字全零——诗面字不进传第二例）；KNOWN 零如实记录（第十八例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 3. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-063-scene' AS id, 'bg-063-scene' AS subject_id, 'context' AS property_key, '八句全诗本文（ws 页 {{另}}×1、其余标记全零、Textquality 75%——单枚异文与不完备并存，正交横截面第六度复现）；异文（君/若）引文含标记原样照登不裁决；同页两形并存三度再验：V018 正文引文系异文取首项的归一文本，本迁移 SCENE 引文含 {{另}} 标记原样，各从其录；穷通之问「不答是答」系读法声明非史料断言（页上无自注）；全句第二引：正文 V018 text claim一引在先（生成时全库查重恰一处，查重针「晚年唯好靜」「漁歌入浦深」各恰一处），两度上限至此用满、此诗正文对后来迁移关闭（audit 硬卡）。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-063-city' AS id, 'bg-063-city' AS subject_id, 'context' AS property_key, '三种消歧形态至此齐备：V059 作者消歧「(王維)」/V061 首句消歧「(山中相送罷)」/本篇裸名锚「==[[酬張少府]]==」（无同名则无消歧器，消歧器有无本身即同名登记，audit 照登硬卡）；卷126 锚+桩恰 2 闭域（机器断言）；底注全锚（同 V058–V061）；{{唐詩三百首}} 标记在本页（与 V061 送別页无标记互为有无）；source-quantangshi-126 系V035/V039/V052/V054/V060 已立、第六次复用零新源；分类行「五言律詩」照登+非史料声明+不升格；通鉴「酬答」全零（赠答往还不进史部）；题面酬答体而无时→零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-063-world' AS id, 'bg-063-world' AS subject_id, 'context' AS property_key, '通鉴「張少府」全零+「少府」恰十二闭域（少府監恰七/少府少監恰四构成断言）——官名在史部只為監署；長策恰七闭域（tj-193/213/235/238×3/248）经国是双句入引=貞觀四年（庚寅，六三〇）安邊之長策+貞元十年（甲戌，七九四）聚斂為長策（闭域+双窗口断言）；解帶恰二闭域全引=貞觀五年（辛卯，六三一）脫巾解帶跪而固諫+光啟二年（丙午，八八六）解帶繫頸而乘之（闭域+双窗口断言）——同字两界第七形态·一首诗双对首见·急閑异位（audit 正入负零双向硬卡）；窮通/舊林通鉴+全唐詩双双全零（诗的问答在两界之外，机器断言）；漁歌全唐詩恰二（vol524/vol525 他人句在册零入引）+好靜恰一（vol218 杜甫句在册不牵合）；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-063-person' AS id, 'bg-063-person' AS subject_id, 'context' AS property_key, '新传「議者不之罪」首引（生成时全库引文域查重：既往零命中，audit 硬卡）；其前换官表句「願歸所任官，放田里」V040 已引在册零重开（audit 硬卡字样）；四字考语不置可否为读法声明非史实；**两传全文靜/長策/解帶/漁歌/少府/窮通/舊林全零**（机器断言——诗面字不进传系列第二例，V061 送字全零之后）；长斋焚香句 V039/V044 在册零重开；已用判例句零重开；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-063-scene' AS subject_id, 'context' AS property_key, 'claim-bg-063-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-063-city' AS subject_id, 'context' AS property_key, 'claim-bg-063-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-063-world' AS subject_id, 'context' AS property_key, 'claim-bg-063-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-063-person' AS subject_id, 'context' AS property_key, 'claim-bg-063-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 4. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-063-scene' AS id, 'work-t300-063' AS work_id, 'SCENE' AS layer, '四联是一场晚年自述的静：晚年只爱清静，万事不关心（「晚年唯好靜，萬事不關心」——诗眼落在一个靜字上，此字两传全文全零，见 PERSON 层）；回头看自己并无治国的长策，只空知要返归旧林（「自顧無長策，空知返舊林」——长策二字史部只作经国是用，诗的长策却是对自己查问、答曰「无」，见 WORLD 层）；松风吹着解开的衣带，山月照着弹奏的琴（「松風吹解帶，山月照彈琴」——解带一刻是全诗最闲的瞬间，而史部的解带恰是跪谏、追銮的最急瞬间，急閑异位，见 WORLD 层）；你若问穷通之理，渔歌已深入水浦——不答是答（「{{另|君|若}}問窮通理，漁歌入浦深」——君一作若，照登；穷通二字史部诗集双双全零，此问在两界之外，不答是答系读法声明，页上无一字自注；此诗正文系**第二引**：V018 text claim 已一引在先（其形系异文取首项的归一文本），全库查重恰一处，两度上限至此用满，此诗正文对后来迁移关闭）。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-063-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-063-city' AS id, 'work-t300-063' AS work_id, 'CITY' AS layer, '篇题锚点是**裸名**的：「==[[酬張少府]]==」没有括号——《唐詩三百首》里没有第二首《酬張少府》，便不需要消歧器。至此同一体系的三种消歧形态齐备：V059 雜詩是**作者消歧**「(王維)」，V061 送別是**首句消歧**「(山中相送罷)」，本篇是**无消歧裸名**——消歧器的有无本身就是同名登记（audit 照登硬卡）。卷126 本篇锚+桩恰 2（闭域机器断言）；底注「↑[[全唐詩/卷126#酬張少府|全唐詩·卷126]]」锚点片段非空（同 V058–V061 全锚形态）；页带 {{唐詩三百首}} 标记（与 V061 送別页无标记互为有无，各按各页原样）；source-quantangshi-126 系 V035/V039/V052/V054/V060 已立、**第六次复用零新源**；分类行「五言律詩」系整理者动作（V048 判例：非史料声明、不升格）；题面「酬」是唱和体例——通鉴「酬答」全零，赠答往还整个不在史部（本层零铸造零 relation）。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-063-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-063-world' AS id, 'work-t300-063' AS work_id, 'WORLD' AS layer, '**題有官名，官名在史部只為監署**：通鉴「張少府」全零；「少府」恰十二处（文件闭域+少府監恰七/少府少監恰四构成断言）——全是官署职事（少府監、少府少監、送少府銷毀），**没有一个「某少府」式的人**：题目里的友人，在史部只存在为一座衙门。**詩有長策解帶，两对字同时两界（同字两界第七形态·一首诗双对首见）**。「長策」恰七处（闭域断言）全是经国是：貞觀四年（庚寅，六三〇）安突厥「**此安邊之長策也**」、貞元十年（甲戌，七九四）陸贄彈延齡「**以聚斂為長策**」——好策坏策都是治国的策；诗的「自顧無長策」是自查，答曰「无」（两句史文逐字入引为判决证据，audit 硬卡）。「解帶」恰二处（闭域+双窗口）且全引：貞觀五年（辛卯，六三一）執失思力「**脫巾解帶**，跪而固諫」、光啟二年（丙午，八八六）杜讓能亂中奔鑾「**解帶**繫頸而乘之」——史部的解帶是**最急的瞬間**（跪諫、追鑾）；诗的「松風吹解帶」是**最閑的瞬間**（松風、山月）——同字两界，急閑异位（两语入引+诗句零混入双向断言）。**詩的問答在兩界之外**：「窮通」「舊林」通鉴与全唐詩双双全零——穷通之理在史与集里都无处问，所以「漁歌入浦深」；「漁歌」全唐詩恰二处（vol524「漁歌聽不唱」/vol525「漁歌對月聽」他人句在册零入引，机器断言）、通鉴全零；「好靜」全唐詩恰一处=vol218 杜甫「好靜心迹素」（他人在册不牵合）。本层零铸造零 relation。' AS body_text, 'SENIOR' AS audience, 'claim-bg-063-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-063-person' AS id, 'work-t300-063' AS work_id, 'PERSON' AS layer, '诗里自查「无长策」，传里他上过一道关涉官位的表：V040 已引新传「願歸所任官，放田里」求换弟弟王縉还京（在册零重开，audit 硬卡字样）；本迁移首引史家对那道表的考语——「**議者不之罪。**」（生成时全库查重：既往零入引，audit 硬卡）：议者不罪，也不褒——**四字考语，不置可否**（读法声明，非史实）。
**两传全文「靜」字全零**（机器断言——写「晚年唯好靜」的人，两篇传里没有靜字；「長策」「解帶」「漁歌」「少府」「窮通」「舊林」两传亦全零）——**诗面字不进传**系列第二例（V061 送字全零之后）：诗的自画像（晚年唯好靜）两传无一字对应，传所记惟仕历与佛事（晚年長齋不衣文綵 V039/退朝之後焚香獨坐 V044 在册零重开）。已用判例句（願歸所任官 V040/召縉句 V061/柴毁骨立 V057/歴右拾遺三连 V059/服除句 V060/輞川系列 V035 起）一个不重开；certainty 不覆盖任何系年。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-063-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 5. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-063-scene' AS claim_id, 'source-ws-t300-063' AS source_id, '页面 酬張少府（header author+四联八句，五段以「……」相連——全句**第二引**：正文 V018 text claim 一引在先（其形系异文取首项的归一文本，本引文含 {{另}} 标记原样——同页两形并存各从其录），生成时全库查重恰一处，**两度上限至此用满，此诗正文对后来迁移关闭**；{{别}}/{{*}}/<ref> 全零、75%；穷通之问不答是答系引者读法声明）' AS locator, '| author   = 王維……晚年唯好靜，萬事不關心。……自顧無長策，空知返舊林。……松風吹解帶，山月照彈琴。……{{另|君|若}}問窮通理，漁歌入浦深。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-063-city' AS claim_id, 'source-ws-t300-063' AS source_id, '页面 酬張少府（header title+页底注+分类行三段并收——题面「酬」系唱和体例；底注全锚「卷126#酬張少府」（同 V058–V061 全锚形态）；{{唐詩三百首}} 标记在本页（与 V061 送別页无标记互为有无，各按各页原样照登）；分类行系整理者动作：非史料声明、不升格）' AS locator, '| title    = 酬張少府……| notes    = {{Textquality|75%}}↑ [[全唐詩/卷126#酬張少府|全唐詩·卷126]]……[[Category:五言律詩]]' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-063-city' AS claim_id, 'source-quantangshi-126' AS source_id, '卷一百二十六·王維《酬張少府》篇题锚点+转引桩（**裸名锚**——无同名诗则无消歧器：对照 V059 作者消歧「(王維)」、V061 首句消歧「(山中相送罷)」，三种消歧形态至此齐备；卷126「酬張少府」恰 2=锚 1+桩 1 机器断言；源行系 V035/V039/V052/V054/V060 已立、本迁移第六次复用零新源）' AS locator, '==[[酬張少府]]==……{{:酬張少府}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-063-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷一百九十三·貞觀四年（庚寅，六三〇）安邊之長策段……卷二百三十五·貞元十年（甲戌，七九四）聚斂為長策段……卷一百九十三·貞觀五年（辛卯，六三一）脫巾解帶跪而固諫段……卷二百五十六·光啟二年（丙午，八八六）解帶繫頸而乘之段（**通鉴「張少府」全零、少府恰十二只为监署、長策恰七、解帶恰二**：文件闭域+四处年标题窗口机器断言——长策只经国是、解带只急变须臾，与诗之自查无策/松风解带同字两界第七形态·双对首见；四句史文逐字入引为判决证据；「窮通」「舊林」通鉴全零——诗的问答在两界之外）' AS locator, '此安邊之長策也。……延齡以聚斂為長策，以詭妄為嘉謀……脫巾解帶，跪而固諫……解帶繫頸而乘之' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-063-person' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百二·文艺中·王維传议者不之罪句（生成时全库引文域查重：既往零入引，本迁移首引；其前换官表句「願歸所任官，放田里」V040 已引零重开；四字考语不置可否是读法声明；两传全文靜字全零——诗面字不进传，机器断言）' AS locator, '議者不之罪。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 6. background_line（八句五律 2/2/2/2 第四次） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-063-scene' AS background_id, 'text-work-t300-063-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-063-scene' AS background_id, 'text-work-t300-063-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-063-city' AS background_id, 'text-work-t300-063-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-063-city' AS background_id, 'text-work-t300-063-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-063-world' AS background_id, 'text-work-t300-063-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-063-world' AS background_id, 'text-work-t300-063-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-063-person' AS background_id, 'text-work-t300-063-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-063-person' AS background_id, 'text-work-t300-063-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 7. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 62, 'Wang Wei''s Response to Vice-Prefect Zhang (work-t300-063) background layers (stage-D poem 43, five-character regulated octet 2/2/2/2 fourth time): dating verdict thirty-seven, twenty-fifth shape of the title-evidence series -- the office title and the two character-pairs in two realms: the string Zhang-Shaofu (the friend named in the title) scores zero across all Tongjian volumes while shaofu appears exactly twelve times (file-closed, constitution-asserted: seven Shofu-jian superintendencies plus four Shao-fu-shao-jian plus one bureau-as-actor) -- never a person, only an office; chang-ce (long stratagem) appears exactly seven times, always statecraft, two lines excerpted as verdict evidence (630 the pacification of the Turks "this is the long stratagem for settling the border", 794 Lu Zhi denouncing Yan Ling "he took hoarding as his long stratagem"), while the poem asks itself for a long stratagem and answers "none"; jie-dai (loosening the sash) appears exactly twice (file-closed, windowed) and both are quoted: in 631 the Turkic commander Chishi Sili removing his cap and loosening his sash to kneel and remonstrate, and in 886 Du Rangneng in the flight toward the emperor loosening his sash to tether a found horse -- in the histories untying the sash marks the most urgent instant, in the poem ("the pine wind blows on my loosened sash") the most leisured: the seventh same-character split, the first time one poem splits two character-pairs at once, urgency against leisure (audit asserts both the four history lines in and the poem''s lines out); qiong-tong (poverty and success) and jiu-lin (the old woods) score zero in BOTH the Tongjian and the Quan Tangshi -- the poem''s question lives outside both realms, hence the answering fisherman''s song (yu-ge: two lines in juan 524/525 by other poets, logged never quoted; hao-jing "loving stillness": exactly one line, Du Fu on the monk Zan, logged never conflated); the disambiguation trio completed: author-disambiguation (V059), first-line disambiguation (V061), and this bare unparenthesized anchor -- whether a disambiguator exists is itself the homonym registry (audit hard-assert); juan 126''s anchor-plus-transclusion exactly two (file-closed) with the base note''s full non-empty fragment (as V058-V061); zero new sources (juan 126''s row reused for the sixth time); one {{另}} marker with 75% (orthogonality sixth time) and same-page two-forms co-existence re-verified a third time; the poem body hits its two-use ceiling (V018 first, twin normalized needles, closure declared); PERSON first-cites the New History''s four-character verdict on his exchange-of-office memorial -- "the deliberators did not blame him" (neither praise nor blame: the earlier memorial sentence stays closed to V040) -- while both entire biographies contain not one occurrence of the character jing (stillness), nor chang-ce, jie-dai, yu-ge, shaofu, qiong-tong or jiu-lin: the poem''s own words never enter the biographies (second instance after the character farewell in V061, machine-asserted); KNOWN zero honestly recorded (eighteenth instance, audit reverse-asserts); closed precedent keywords stay out of citations'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 62);
COMMIT;
