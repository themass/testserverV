-- V060：王維《歸嵩山作》(work-t300-136) 四层背景（阶段 D 第 41 首·嵩山与闭关）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V014、V015、V016、V018、V035、V039、V052、V054、V059 已执行（work-t300-136 与其
--       text-work-t300-136-ws、source-ws-t300-136 是 V018 的行；source-quantangshi-126 是
--       V035/V039/V052/V054 已立的卷126 源行（本迁移第五次复用，零新源）；
--       source-jiutangshu-wenyuan 是 V016 的行；source-xintangshu-wenyi 是 V016 的行；
--       source-zizhi-tongjian-events 是 V014/V015 已立的通鉴事件源）。
--       本迁移零新 source（audit 断言无诗源表新建插入语句）。
--
-- 数据源（可复现）：emit_v060.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/歸嵩山作.txt（{{另}}×3×75% 正交第四度+第三枚恰落判决词位）、
--   舊唐書卷190下（服阕句二引）、新唐書卷202（服除句首引）、
--   全唐詩卷126（锚桩）+卷128（送方尊師歸嵩山在册结构）、
--   通鑑卷191/205/227/229（嵩山逐卷闭域+閉關恰三+四处年标题窗口）+ 通鑑 75 卷/
--   全唐詩 118 卷存快照负证计数扫描（嵩山/嵩高/閉關/掩關/迢遞/荒城/古渡/秋山/
--   長薄/閑閑/落日/暮禽/暮雲/清川/歸來/歸嵩山）+
--   既有迁移引文域逐句查重——传区间归属、首引/二引/零重开前提全部生成时断言。
--
-- 做：4 BACKGROUND content/claim/background + 6 组逐字引用（(claim,source) 主键每对恰一行）+
--   8 行 background_line（八句五律 2/2/2/2 第三次，同 V054/V058）+ 零 poetry_source 行
--   + 不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「題有山名，山在史部一封祀一隱遁；詩用閉關，閉關在史部只城門與關梁」）：
--   * 嵩山恰 18 逐卷闭域（九卷分布机器断言）；閉關恰三+四窗口入引为判决证据；
--   * 异文支史部命中数不同：閉/掩——「掩關」通鉴全零，撞字论断只辖「閉關」支（新边界首录）；
--   * 同页两形并存首录：V018 正文引文异文归一形，本迁移 SCENE 标记原样形，各从其录；
--   * 此诗正文第二引上限用满：V018 一引在先（查重针归一形恰一处），对后来迁移关闭；
--   * 旧传服阕句 V059 一引在先本迁移二引关闭；新传服除句首引；两传阶次俱异不得合并；
--   * 丧门/衙门与门之方向掉转均标明读法声明非史实；
--   * KNOWN 零如实记录（第十六例，audit 反向断言 SQL 无 KNOWN 字面量）；
--   * 柴毁骨立（V057）/事母崔氏（V055）/茶鐺（V054）/歴右拾遺三连（V059）判例只引不重开。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 59，不含 60
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-136-%';             -- 空
--   SELECT id FROM poetry_source WHERE id='source-quantangshi-126';     -- 恰 1（V035 起四迁移已立，本迁移复用不新建）
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-136-ws';  -- 恰 8
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-136-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-136';                                  -- 8（2/2/2/2）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-136-%';  -- 四行全 LIKELY（有意全 LIKELY）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-136'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-136';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-136-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
--   SELECT COUNT(*) FROM poetry_source WHERE id='source-quantangshi-126';  -- 恰 1（复用，非本迁移所立）
-- 回滚: recovery/V060_rollback.sql（按 id 全枚举删除；零 source 删除——卷126 源行为 V035 起所立）
START TRANSACTION;

-- ---------- 1. 零新 source（卷126 源行 V035/V039/V052/V054 已立，本迁移第五次复用） ----------
-- ---------- 2. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-136-scene' AS id, 'BACKGROUND' AS entity_type, '136-scene' AS slug, '眼前：越走越静的一条归路' AS title, '四层处境背景（阶段 D 第 41 首·八句五律 2/2/2/2 第三次）；史实句均有逐字引证；系年第三十五次判决（题证系列第廿三状·嵩山与闭关）「題有山名，山在史部一封祀一隱遁；詩用閉關，閉關在史部只城門與關梁」——通鉴「嵩山」恰 18 处逐卷闭域（九卷）：封祀派（有事/罢封/奉天宫/数幸）与隐遁派而隐遁系考场（万岁通天元年（丙申，六九六）武攸绪「隱於嵩山之陽，太后疑其詐」首引入引）；「閉關」恰三（闭域+三窗口：玄武门锁城/李长春等官军/韩滉断道）——同字两界第五形态，四段史文逐字入引为判决证据；异文支史部命中数不同（閉/掩——掩關通鉴全零，撞字论断只辖闭关支，新边界首录）；诗语十二词通鉴全零；ws {{另}}×3 与 75% 并存正交第四度；第三枚异文恰落判决词位照登；同页两形并存首录（V018 归一形 vs 本迁移标记原样）；「歸嵩山」题族恰 4（同诗人两题在册不引）；零新源（卷126 第五次复用）；此诗正文第二引上限用满对后来关闭（V018 在先+全库查重）；两传同事异词并置第二例（旧传服阕句 V059 一引在先二引关闭×新传服除句首引；阶次俱异更不得合并）；KNOWN 零如实记录（第十六例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-136-city' AS id, 'BACKGROUND' AS entity_type, '136-city' AS slug, '这座城：判决词恰在异文位上' AS title, '四层处境背景（阶段 D 第 41 首·八句五律 2/2/2/2 第三次）；史实句均有逐字引证；系年第三十五次判决（题证系列第廿三状·嵩山与闭关）「題有山名，山在史部一封祀一隱遁；詩用閉關，閉關在史部只城門與關梁」——通鉴「嵩山」恰 18 处逐卷闭域（九卷）：封祀派（有事/罢封/奉天宫/数幸）与隐遁派而隐遁系考场（万岁通天元年（丙申，六九六）武攸绪「隱於嵩山之陽，太后疑其詐」首引入引）；「閉關」恰三（闭域+三窗口：玄武门锁城/李长春等官军/韩滉断道）——同字两界第五形态，四段史文逐字入引为判决证据；异文支史部命中数不同（閉/掩——掩關通鉴全零，撞字论断只辖闭关支，新边界首录）；诗语十二词通鉴全零；ws {{另}}×3 与 75% 并存正交第四度；第三枚异文恰落判决词位照登；同页两形并存首录（V018 归一形 vs 本迁移标记原样）；「歸嵩山」题族恰 4（同诗人两题在册不引）；零新源（卷126 第五次复用）；此诗正文第二引上限用满对后来关闭（V018 在先+全库查重）；两传同事异词并置第二例（旧传服阕句 V059 一引在先二引关闭×新传服除句首引；阶次俱异更不得合并）；KNOWN 零如实记录（第十六例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-136-world' AS id, 'BACKGROUND' AS entity_type, '136-world' AS slug, '这个天下：山的两界与门的两种关法' AS title, '四层处境背景（阶段 D 第 41 首·八句五律 2/2/2/2 第三次）；史实句均有逐字引证；系年第三十五次判决（题证系列第廿三状·嵩山与闭关）「題有山名，山在史部一封祀一隱遁；詩用閉關，閉關在史部只城門與關梁」——通鉴「嵩山」恰 18 处逐卷闭域（九卷）：封祀派（有事/罢封/奉天宫/数幸）与隐遁派而隐遁系考场（万岁通天元年（丙申，六九六）武攸绪「隱於嵩山之陽，太后疑其詐」首引入引）；「閉關」恰三（闭域+三窗口：玄武门锁城/李长春等官军/韩滉断道）——同字两界第五形态，四段史文逐字入引为判决证据；异文支史部命中数不同（閉/掩——掩關通鉴全零，撞字论断只辖闭关支，新边界首录）；诗语十二词通鉴全零；ws {{另}}×3 与 75% 并存正交第四度；第三枚异文恰落判决词位照登；同页两形并存首录（V018 归一形 vs 本迁移标记原样）；「歸嵩山」题族恰 4（同诗人两题在册不引）；零新源（卷126 第五次复用）；此诗正文第二引上限用满对后来关闭（V018 在先+全库查重）；两传同事异词并置第二例（旧传服阕句 V059 一引在先二引关闭×新传服除句首引；阶次俱异更不得合并）；KNOWN 零如实记录（第十六例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-136-person' AS id, 'BACKGROUND' AS entity_type, '136-person' AS slug, '这个人：从丧门到衙门' AS title, '四层处境背景（阶段 D 第 41 首·八句五律 2/2/2/2 第三次）；史实句均有逐字引证；系年第三十五次判决（题证系列第廿三状·嵩山与闭关）「題有山名，山在史部一封祀一隱遁；詩用閉關，閉關在史部只城門與關梁」——通鉴「嵩山」恰 18 处逐卷闭域（九卷）：封祀派（有事/罢封/奉天宫/数幸）与隐遁派而隐遁系考场（万岁通天元年（丙申，六九六）武攸绪「隱於嵩山之陽，太后疑其詐」首引入引）；「閉關」恰三（闭域+三窗口：玄武门锁城/李长春等官军/韩滉断道）——同字两界第五形态，四段史文逐字入引为判决证据；异文支史部命中数不同（閉/掩——掩關通鉴全零，撞字论断只辖闭关支，新边界首录）；诗语十二词通鉴全零；ws {{另}}×3 与 75% 并存正交第四度；第三枚异文恰落判决词位照登；同页两形并存首录（V018 归一形 vs 本迁移标记原样）；「歸嵩山」题族恰 4（同诗人两题在册不引）；零新源（卷126 第五次复用）；此诗正文第二引上限用满对后来关闭（V018 在先+全库查重）；两传同事异词并置第二例（旧传服阕句 V059 一引在先二引关闭×新传服除句首引；阶次俱异更不得合并）；KNOWN 零如实记录（第十六例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 3. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-136-scene' AS id, 'bg-136-scene' AS subject_id, 'context' AS property_key, '八句全诗本文（ws 页 {{另}}×3、其余标记全零、Textquality 75%——三枚异文与不完备并存，正交第四度再验）；三枚异文（清/晴、禽/雲、閉/掩）引文含标记原样照登不裁决；**同页两形并存首录**：V018 正文引文系异文取首项的归一文本，本迁移 SCENE 引文含标记原样，各从其录两形在案；全句第二引：正文 V018 text claim 一引在先（生成时全库查重恰一处，查重针取归一形「歸來且閉關」），两度上限至此用满、此诗正文对后来迁移关闭（audit 硬卡）。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-136-city' AS id, 'bg-136-city' AS subject_id, 'context' AS property_key, '底注锚点片段非空（同 V058/V059 全锚形态，audit 硬卡字样）；source-quantangshi-126 系 V035/V039/V052/V054 已立、第五次复用零新源（audit 反向断言无诗源表新建插入语句）；卷126 无消歧直锚+桩各恰一；第三枚异文恰落判决词位（閉/掩）——撞字论断只辖「閉關」支，「掩關」通鉴全零（异文支史部命中数不同，新边界首录，机器断言）；「歸嵩山」题族恰 4=本篇 2+王维《送方尊師歸嵩山》（卷128）2（同诗人两题在册不引，机器断言分布）；分类行「五言律詩」照登+非史料声明+不升格；题有山名而无时→零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-136-world' AS id, 'bg-136-world' AS subject_id, 'context' AS property_key, '嵩山恰 18 处逐卷闭域（九卷分布机器断言）——封祀现场（有事/罢封/奉天宫/数幸）与隐遁考场（万岁通天元年（丙申，六九六）武攸绪「隱於嵩山之陽，太后疑其詐」首引入引为判决证据）两派；閉關恰三逐卷闭域+三窗口（武德九年玄武门张公谨闭关以拒之/建中三年李长春闭关不內/建中四年韩滉闭关梁——锁城/等官军/断道皆城门关梁事，逐字入引为判决证据）——与诗中掩门归隐同字两界第五形态；「嵩高」「迢遞」「掩關」等诗语十二词通鉴全零（机器断言）；两传王维段嵩/閉關/迢遞全零；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-136-person' AS id, 'bg-136-person' AS subject_id, 'context' AS property_key, '两传同事异词并置第二例（V057 首见「合而不并」之后）：旧传「服闋，拜吏部郎中」系 V059 一引在册（全库查重恰一处=V059，本迁移子句二引上限用满对后来关闭）×新传「服除，累遷給事中」生成时全库查重既往零入引首引（audit 硬卡）；两书连迁转阶次所记不同（吏部郎中 vs 给事中）——更不得合并（词异与阶异双向互斥断言）；丧门/衙门与诗门方向掉转为读法声明非史实；已用判例句零重开；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-136-scene' AS subject_id, 'context' AS property_key, 'claim-bg-136-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-136-city' AS subject_id, 'context' AS property_key, 'claim-bg-136-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-136-world' AS subject_id, 'context' AS property_key, 'claim-bg-136-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-136-person' AS subject_id, 'context' AS property_key, 'claim-bg-136-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 4. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-136-scene' AS id, 'work-t300-136' AS work_id, 'SCENE' AS layer, '八句是一条回家的路，越走越静：清川挟着长长的草木，车马也走得不慌不忙（「{{另|清|晴}}川帶長薄，車馬去閑閑」——川作「清」一作「晴」，照登）；流水若是有心，连暮色里的飞鸟都结伴同归（「流水如有意，暮{{另|禽|雲}}相與還」——禽作「暮禽」一作「暮雲」，照登）；荒城对着古渡，落日铺满秋山（「荒城臨古渡，落日滿秋山」——无标记联，全诗最阔大的一笔偏是荒与古）；迢迢递递的嵩高之下，回来，且把门掩上（「迢遞嵩高下，歸來且{{另|閉|掩}}關」——闭一作掩，照登；此诗正文系**第二引**：V018 text claim 已一引在先（其形系异文取首项的归一文本），全库查重恰一处，两度上限至此用满，此诗正文对后来迁移关闭）。**同页两形并存**：V018 正文引文标记归一（各取 {{另}} 首项），本迁移 SCENE引文含三枚标记原样——各从其录，两形都在案。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-136-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-136-city' AS id, 'work-t300-136' AS work_id, 'CITY' AS layer, '页 {{另}} 恰三（清/晴、禽/雲、閉/掩）而 {{别}}/{{*}}/<ref> 全零、Textquality 75%（三枚异文与 75% 并存，正交横截面第四度复现）。**第三枚异文恰落在判决词上**：「歸來且{{另|閉|掩}}關」——闭一作掩；下面 WORLD 层的撞字论断**只辖「閉關」支**：通鉴「掩關」全零（机器断言）——同一行诗的异文两支在史部的命中数不同，照登不裁决。页底注「↑ [[全唐詩/卷126#歸嵩山作|全唐詩·卷126]]」锚点片段非空（同 V058/V059 全锚形态）；source-quantangshi-126 系 V035/V039/V052/V054四迁移已立，本迁移第五次复用，**零新源**；卷126 本篇为无消歧直锚+转引桩（机器断言各恰一）。「歸嵩山」题族全唐詩恰 4=本篇锚桩 2+王维自己另一首《送方尊師歸嵩山》（卷128）锚桩 2——**同一位诗人两次把「归嵩山」写进题目**（在册不引不牵合，机器断言分布）。分类行「五言律詩」系整理者动作（V048 判例三重断言）。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-136-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-136-world' AS id, 'work-t300-136' AS work_id, 'WORLD' AS layer, '诗往嵩山去，史里的嵩山恰 18 处、恰九卷（逐卷计数闭域机器断言），处处不是这条归路。一派是**封祀的现场**：詔「有事於嵩山」、「罷封嵩山」、「作奉天宮於嵩山南」、太后数幸嵩山。另一派看似同调——也隐居——却是**被考问的**：萬歲通天元年（丙申，六九六）武攸緒「**扈從封中岳還，即求棄官，隱於嵩山之陽。太后疑其詐，許之，以觀其所為。**」——**史部的嵩山连隐遁都是一场考场**，朝廷要看他真隐假隐。诗里的归山无人考问，归心自决，这正是诗与史的分界。
**同字两界第五形态（闭）**：诗的收束是「歸來且閉關」——掩门归隐；通鉴「閉關」恰三处（闭域+三窗口断言），处处是城门与关梁：武德九年（丙戌，六二六）玄武门之变張公謹「獨閉關以拒之」（锁城）；建中三年（壬戌，七八二）李長春「閉關不內，以俟官軍」（等官军）；建中四年（癸亥，七八三）韓滉「閉關梁」禁马牛出境（断道禁行）——**史部的闭关把门关上是为了不让进出，诗的闭关把门关上是为了不再过问**。「嵩高」「迢遞」「荒城」「古渡」「秋山」「長薄」「閑閑」「落日」「暮禽」「暮雲」「清川」「歸來」通鉴全零（机器断言十二连）——**归途的语言整条进不了史部**；两传王维段「嵩」「閉關」「迢遞」全零（传写其人，不提这座山）。本层零铸造零 relation。' AS body_text, 'SENIOR' AS audience, 'claim-bg-136-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-136-person' AS id, 'work-t300-136' AS work_id, 'PERSON' AS layer, '写归山的人，传里先写的却是他不得不一再出门任职。丧假结束那道门，两部书各有一句：旧传「**服闋，拜吏部郎中。**」×新传「**服除，累遷給事中。**」——**两传同事异词第二例（V057 母丧「柴毁骨立」×「毀幾不生」之后）**：同一件事（服丧结束、复职迁转），措辞不同，**连迁转的阶次都记不同**（旧传接吏部郎中、新传径接给事中）——各自逐字并引、并列不合并（合而不并第二用，词异互斥 audit 双向硬卡）。旧传句系 V059 行迹三连已一引在册（全库查重恰一处），本迁移子句二引对后来关闭；新传句生成时全库查重既往零入引，本迁移首引。
**服闋/服除正是丧期结束的行话，两传都用它起句，紧接的都是官职**——传体的王维永远从丧门走向衙门；诗里的王维「歸來且閉關」，门的方向掉转过来（读法声明，非史实）。已用判例句（柴毁骨立 V057/事母崔氏 V055/茶鐺 V054/歴右拾遺三连 V059/輞川系列 V035 起）一个不重开；certainty 不覆盖任何系年。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-136-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 5. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-136-scene' AS claim_id, 'source-ws-t300-136' AS source_id, '页面 歸嵩山作（header author+四联八句，五段以「……」相連——全句**第二引**：正文 V018 text claim 一引在先（其形系异文取首项的归一文本，本引文含 {{另}}×3 标记原样——同页两形并存各从其录），生成时全库查重恰一处，**两度上限至此用满，此诗正文对后来迁移关闭**；{{别}}/{{*}}/<ref> 全零、75%）' AS locator, '| author   = 王維……{{另|清|晴}}川帶長薄，車馬去閑閑。……流水如有意，暮{{另|禽|雲}}相與還。……荒城臨古渡，落日滿秋山。……迢遞嵩高下，歸來且{{另|閉|掩}}關。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-136-city' AS claim_id, 'source-ws-t300-136' AS source_id, '页面 歸嵩山作（header title+页底注+分类行三段并收——底注「卷126#歸嵩山作」锚点片段非空（同 V058/V059 全锚形态）；第三枚 {{另|閉|掩}} 恰落判决词位，异文两支在史部命中数不同照登不裁决；分类行系整理者动作：非史料声明、不升格）' AS locator, '| title    = 歸嵩山作……| notes    = {{Textquality|75%}}↑ [[全唐詩/卷126#歸嵩山作|全唐詩·卷126]]……[[Category:五言律詩]]' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-136-city' AS claim_id, 'source-quantangshi-126' AS source_id, '卷一百二十六·王維《歸嵩山作》篇题锚点+转引桩（无消歧直锚——机器断言各恰一；源行系 V035/V039/V052/V054 已立、本迁移第五次复用零新源；「歸嵩山」题族恰 4 含卷128《送方尊師歸嵩山》锚桩在册不引）' AS locator, '==[[歸嵩山作]]==……{{:歸嵩山作}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-136-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷二百五·萬歲通天元年（丙申，六九六）武攸緒隱嵩山之陽段……卷一百九十一·武德九年（丙戌，六二六）玄武門張公謹閉關段……卷二百二十七·建中三年（壬戌，七八二）李長春閉關不內段……卷二百二十九·建中四年（癸亥，七八三）韓滉閉關梁段（**嵩山恰十八逐卷闭域+閉關恰三+四处年标题窗口机器断言**——史部的嵩山一为封祀现场一为隐遁考场，闭关皆城门关梁事：锁城/等官军/断道，与诗中掩门归隐同字两界第五形态，四段史文皆逐字入引作判决证据；「掩關」支通鉴全零在册）' AS locator, '扈從封中岳還，即求棄官，隱於嵩山之陽。太后疑其詐，許之，以觀其所為。……張公謹多力，獨閉關以拒之，不得入。……大將李長春閉關不內，以俟官軍……浙江東、西節度使韓滉閉關梁' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-136-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·王維传服阕句（V059 行迹三连已一引在册——全库查重恰一处，本迁移子句二引对后来关闭；与新传服除句同事异词异阶，并列不合并）' AS locator, '服闋，拜吏部郎中。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-136-person' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百二·文艺中·王維传服除句（生成时全库引文域查重：既往零入引，本迁移首引；与旧传服阕句同记服丧结束复职而措辞与阶次俱异——合而不并第二用；与诗中「歸來且閉關」门之方向掉转并置是读法声明）' AS locator, '服除，累遷給事中。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 6. background_line（八句 2/2/2/2） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-136-scene' AS background_id, 'text-work-t300-136-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-136-scene' AS background_id, 'text-work-t300-136-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-136-city' AS background_id, 'text-work-t300-136-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-136-city' AS background_id, 'text-work-t300-136-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-136-world' AS background_id, 'text-work-t300-136-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-136-world' AS background_id, 'text-work-t300-136-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-136-person' AS background_id, 'text-work-t300-136-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-136-person' AS background_id, 'text-work-t300-136-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 7. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 60, 'Wang Wei Returning to Mount Song (work-t300-136) background layers (stage-D poem 41, eight-line regulated verse 2/2/2/2, third use): dating verdict thirty-five, twenty-third shape of the title-evidence series -- the mountain and the closed gate in two realms: Mount Song appears exactly eighteen times across exactly nine Tongjian volumes (file-by-file closed-domain machine assertion): on one side the imperial sacrifice -- edicts to perform the rite on Song, its cancellation, the Fengtian palace built south of the mountain, the empress dowager''s repeated processions; on the other side reclusion that is an examination -- in 696 Wu Youxu, returning from escorting the Zhongyue封 rite, begs to resign and hides on Song''s sunny side, and the empress dowager, suspecting a trick, grants it "to watch what he will do" (first citation, excerpted as verdict evidence): in the histories even hiding on Song is a test the court administers, while the poem''s return is unexamined and self-decided; closing the gate, the fifth same-character split: the poem ends "returning, I shut the gate", while the Tongjian''s three shut-the-gate passages (file-closed, triple year-heading windows) all mean gates of cities and communications: at Xuanwu Gate in 626 Zhang Gongjin shut the gate to bar the princes, in 782 Li Changchun shut the gate to wait for government troops, in 783 Han Huang shut the passes and banned cattle and horses from leaving -- gates shut against movement, not against worldly concern; and a new boundary first recorded: the variant reading matters for historiography -- the third {{另}} marker sits exactly on the verdict word (閉/掩), and the alternate branch "yan-guan" scores zero across the Tongjian, so the character-collision claim binds only to the bi-guan branch (machine-asserted, logged, never adjudicated); twelve poem-words score zero across the Tongjian -- the language of the homeward road cannot enter the histories; ws page carries three {{另}} markers with 75% completeness (orthogonality fourth time); same-page two-forms co-existence first registered: V018''s body excerpt normalizes markers to their first items, this migration''s SCENE quotes them verbatim, each recorded its own way; the title-family gui-Song-shan counts exactly 4 (this poem''s anchor plus Wang Wei''s own Sending Off Master Fang Returning to Song in juan 128, logged never quoted); zero new sources (juan 126''s row reused for the fifth time); the poem body hits its two-use ceiling (V018 first, machine-swept with the normalized needle, closure declared); PERSON second instance of two histories worded differently for one event (Old History''s mourning-end sentence second use closing after V059, New History''s first-cited; even the offices named differ, so merging is doubly barred, mutual-exclusion asserted); KNOWN zero honestly recorded (sixteenth instance, audit reverse-asserts); closed precedent keywords stay out of citations'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 60);
COMMIT;
