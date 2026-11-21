-- V051：孟浩然《夏日南亭懷辛大》(work-t300-108) 四层背景（阶段 D 第 32 首·十句五排）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V014、V015、V016、V018、V031、V048、V049、V050 已执行（work-t300-108 与其
--       text-work-t300-108-ws、source-ws-t300-108 是 V018 的行；source-xintangshu-wenyi 是 V016 的行；
--       source-quantangshi-160 是 V031 的行；source-zizhi-tongjian-events 是 V014/V015 已立的通鉴事件源）。
--       本迁移新立 source 恰一个：source-quantangshi-159（断言）——V018 从未立 159、V031 只立了 160。
--
-- 数据源（可复现）：emit_v051.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/夏日南亭懷辛大.txt（题内 {{另}} 首见，{{另}} 恰二处断言）、
--   舊唐書卷190下 / 新唐書卷203（孟段负证+雅称道句）、全唐詩卷159/160（辛大四锚点×2 结构）、
--   通鑑卷225/226（盧子期两段）+ 通鑑 75 卷/全唐詩 120 卷负证计数扫描——
--   传区间归属、大曆十年→十一年窗口、伯牙/鍾期/子期/辛大 全部计数与结构生成时断言。
--
-- 做：1 个新 source（source-quantangshi-159，恰一处 INSERT，断言）+
--   4 BACKGROUND content/claim/background + 6 组逐字引用（(claim,source) 主键每对恰一行）+
--   10 行 background_line（十句形制：scene→1-4 city→5-6 world→7-8 person→9-10，
--   绑 text-work-t300-108-ws 的 10 行）。本迁移不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「題有季有友，季是節非年、友有第無名」）：
--   * 夏日=每到不是某年（V048 周期时间判例）；辛大只传行第：两传零见、
--     全唐詩恰八处=四档篇题×2、辛大夫六处另册（机器结构断言）——人只活在诗世界；
--   * 知音典：伯牙/鍾期通鉴+全唐詩计数全零；子期恰六处全归叛将盧子期
--     （前字 {盧,破,擒}+文件闭域+775→776 窗口三重断言）——同名不同人不牵合；
--   * 异衔不牵合：刘长卿卷辛大夫诸篇登记在场、零入引（V047 纪律）；
--   * 题内 {{另|日|夕}} 首见：题面标记逐字入 CITY 引文（照登双卡之一）；
--   * KNOWN 零如实记录（audit 反向断言 SQL 无 KNOWN 字面量）；
--   * 夏夜四拍/庙堂称扬与草堂想念/两个子期并置均为读法声明，audit 双声明在 BG 文本内；
--   * 不才/放還/韓朝宗/遑恤他/鹿門/孟亭/畫浩然像/病疽背卒/刻碑 判例只引不重开。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 50，不含 51
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-108-%';             -- 空
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-108-ws';  -- 恰 10（五排）
--   SELECT id FROM poetry_source WHERE id='source-quantangshi-159';     -- 空（本迁移新立）
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-108-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-108';                                  -- 10（4/2/2/2）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-108-%';  -- 四行全 LIKELY（有意全 LIKELY）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-108'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-108';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-108-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
--   SELECT COUNT(*) FROM poetry_source WHERE id='source-quantangshi-159';  -- 恰 1（本迁移新立）
-- 回滚: recovery/V051_rollback.sql（按 id 全枚举删除，含新立的 source 行；
--   不动 V014/V015/V016/V018/V031 的行，不动其余共用来源行）
START TRANSACTION;

-- ---------- 0. 新立 source：全唐詩卷159（恰一个，断言在生成器 audit） ----------
INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status, source_kind, reliability)
SELECT * FROM (
SELECT 'source-quantangshi-159' AS id, '《全唐詩》全唐詩/卷159（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷159（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷159' AS url, '维基文库录入本，公有领域古籍。本卷为孟浩然诗卷，卷首 Collection header notes 标作者 ''''''孟浩然''''''。本卷条目只有锚点+转引用桩，正文在诗页。本行由 emit_v051.py 对快照逐字定位。核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status, 'POETRY_COLLECTION' AS source_kind, 'HIGH' AS reliability FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_source x WHERE x.id = t.id);

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-108-scene' AS id, 'BACKGROUND' AS entity_type, '108-scene' AS slug, '眼前：一个夏夜独自凉下来' AS title, '四层处境背景（阶段 D 第 32 首·十句五排 4/2/2/2 形制首用）；史实句均有逐字引证；系年第二十六次判决「題有季有友，季是節非年、友有第無名」（题证系列第十四状·周期季与行第友——夏日如重阳是每到不是某年，辛大只传行第：两传零见、全唐詩恰四档篇题×2 结构机器断言）→time.span/event.name/written_during 全缺席、零 relation；典名零见+同名不同人防线：伯牙全库零、子期恰六处全归叛将盧子期（前字断言+文件闭域+大曆十年→十一年窗口）；题内 {{另|日|夕}} 标记首见——照登双卡（题面+山光句）；KNOWN 零如实记录（雅称道句单得、卢子期段各单得——都不升）；异衔不牵合（刘长卿卷辛大夫登记不引）；新立 source 恰一个（source-quantangshi-159，audit 断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-108-city' AS id, 'BACKGROUND' AS entity_type, '108-city' AS slug, '这座城：诗世界里的南亭与辛大' AS title, '四层处境背景（阶段 D 第 32 首·十句五排 4/2/2/2 形制首用）；史实句均有逐字引证；系年第二十六次判决「題有季有友，季是節非年、友有第無名」（题证系列第十四状·周期季与行第友——夏日如重阳是每到不是某年，辛大只传行第：两传零见、全唐詩恰四档篇题×2 结构机器断言）→time.span/event.name/written_during 全缺席、零 relation；典名零见+同名不同人防线：伯牙全库零、子期恰六处全归叛将盧子期（前字断言+文件闭域+大曆十年→十一年窗口）；题内 {{另|日|夕}} 标记首见——照登双卡（题面+山光句）；KNOWN 零如实记录（雅称道句单得、卢子期段各单得——都不升）；异衔不牵合（刘长卿卷辛大夫登记不引）；新立 source 恰一个（source-quantangshi-159，audit 断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-108-world' AS id, 'BACKGROUND' AS entity_type, '108-world' AS slug, '这个天下：被叛将占用的名字' AS title, '四层处境背景（阶段 D 第 32 首·十句五排 4/2/2/2 形制首用）；史实句均有逐字引证；系年第二十六次判决「題有季有友，季是節非年、友有第無名」（题证系列第十四状·周期季与行第友——夏日如重阳是每到不是某年，辛大只传行第：两传零见、全唐詩恰四档篇题×2 结构机器断言）→time.span/event.name/written_during 全缺席、零 relation；典名零见+同名不同人防线：伯牙全库零、子期恰六处全归叛将盧子期（前字断言+文件闭域+大曆十年→十一年窗口）；题内 {{另|日|夕}} 标记首见——照登双卡（题面+山光句）；KNOWN 零如实记录（雅称道句单得、卢子期段各单得——都不升）；异衔不牵合（刘长卿卷辛大夫登记不引）；新立 source 恰一个（source-quantangshi-159，audit 断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-108-person' AS id, 'BACKGROUND' AS entity_type, '108-person' AS slug, '这个人：庙堂称扬与草堂想念' AS title, '四层处境背景（阶段 D 第 32 首·十句五排 4/2/2/2 形制首用）；史实句均有逐字引证；系年第二十六次判决「題有季有友，季是節非年、友有第無名」（题证系列第十四状·周期季与行第友——夏日如重阳是每到不是某年，辛大只传行第：两传零见、全唐詩恰四档篇题×2 结构机器断言）→time.span/event.name/written_during 全缺席、零 relation；典名零见+同名不同人防线：伯牙全库零、子期恰六处全归叛将盧子期（前字断言+文件闭域+大曆十年→十一年窗口）；题内 {{另|日|夕}} 标记首见——照登双卡（题面+山光句）；KNOWN 零如实记录（雅称道句单得、卢子期段各单得——都不升）；异衔不牵合（刘长卿卷辛大夫登记不引）；新立 source 恰一个（source-quantangshi-159，audit 断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-108-scene' AS id, 'bg-108-scene' AS subject_id, 'context' AS property_key, '十句全诗本文（ws 页 {{另}} 恰二处——题内+山光句，异文照登反向极性双卡：两处标记字样分别入 CITY/SCENE 引文，V044 判例；Textquality 75% 如实记）；夏夜四拍/琴拿起来听众缺席为本层读法声明，非史料断言。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-108-city' AS id, 'bg-108-city' AS subject_id, 'context' AS property_key, '友有第无名：辛大两传孟区间计数全零（机器断言）；诗世界四档：全唐詩「辛大」（除辛大夫六处另册）恰 8=（卷159 两枚+卷160 两枚）篇题锚点×2 结构断言，四枚全数逐字入引；异衔登记不引：辛大夫六处（卷148 四处+卷151 二处）无从指认同人（V047 纪律）；题内 {{另|日|夕}} 首见照登不裁决；底注+分类行照登+非史料声明+不升格；季是節非年、友有第無名→零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-108-world' AS id, 'bg-108-world' AS subject_id, 'context' AS property_key, '典名零见：伯牙/鍾子期/絕弦通鉴+全唐詩计数全零、鍾期全库恰一处且在他卷他人挽诗（机器闭域断言，登记不引）——典在诗世界不在史部（V046/V050 同族第三例）；子期恰六处全归叛将盧子期（前字 {盧,破,擒} 机器断言+tj-225/226 文件闭域断言+大曆十年→十一年年标题窗口断言）——同名不同人防线；时距声明（诗人開元末已卒，775 年登场者为另一子期）为读法声明；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-108-person' AS id, 'bg-108-person' AS subject_id, 'context' AS property_key, '新传雅称道句单得（旧传孟段无稱道语，生成时机器断言）→不升；庙堂称扬与草堂想念并置为读法声明；判例零重开（不才/放還/韓朝宗/遑恤他/鹿門/孟亭/畫浩然像/病疽背卒/刻碑——audit 关键语硬卡）；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-108-scene' AS subject_id, 'context' AS property_key, 'claim-bg-108-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-108-city' AS subject_id, 'context' AS property_key, 'claim-bg-108-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-108-world' AS subject_id, 'context' AS property_key, 'claim-bg-108-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-108-person' AS subject_id, 'context' AS property_key, 'claim-bg-108-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-108-scene' AS id, 'work-t300-108' AS work_id, 'SCENE' AS layer, '十句是一个夏夜独自凉下来的完整过程：山的光亮忽然往西沉（「山光忽西{{另|落|發}}」——此句页内挂 {{另}} 异文：落/發，照登不裁决），池上的月亮慢慢往东爬；披散着头发乘这傍晚的凉，打开窗卧看宽敞的夜（「散髮乘夕涼，開軒臥閑敞」——一天里最松弛的姿势）；风把荷香送来，竹上的露滴成清响（「荷風送香氣，竹露滴清響」——鼻子和耳朵先于心里）；想取琴弹一曲，恨没有知音来赏（「欲取鳴琴彈，恨無知音賞」——琴拿起来了，听众缺席）；有此感触便想起故人，半夜里神魂都为想念所劳（「感此懷故人，中宵勞夢想」——十句收在一个人的想念上）。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-108-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-108-city' AS id, 'work-t300-108' AS work_id, 'CITY' AS layer, '这座「城」是一座南亭——它的档案全在诗里。题面本身就带异文：「夏{{另|日|夕}}南亭懷辛大」——日/夕两支在题目字段里并挂（题内 {{另}} 首见），照登不裁决。诗里的朋友「辛大」在两传孟区间计数全零（机器断言）——唐人呼行第不呼名，传不替他登记；但在全唐詩，「辛大」（异衔「辛大夫」六处另册）恰八处=四枚篇题锚点×2（V050 卷160 同款结构）：卷159《夏日南亭懷辛大》本篇与《送辛大之鄂渚不及》、卷160《都下送辛大之鄂》与《張七及辛大見尋南亭醉作》（四枚篇题锚点逐字入引，机器 8=4×2 结构断言）——**辛大只活在诗世界，而且活得热闹**：送他、怀他、等他醉闯南亭。同一座南亭、同一个辛大，就在本集另一首诗的门口。
另登记不引：全唐詩刘长卿卷有「辛大夫」诸篇——衔称不同无从指认同人，异衔不牵合（V047 同姓不同人纪律）。页底注与分类行（仄韻五排）为整理者动作：照登+非史料声明+不升格（V048 分类行判例）。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-108-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-108-world' AS id, 'work-t300-108' AS work_id, 'WORLD' AS layer, '「恨無知音賞」押的是伯牙子期的知音典——但快照史部里这个典**连名字都没有**：「伯牙」通鉴 75 卷+全唐詩 120 卷计数全零，「鍾子期」「絕弦」亦全零（V046 典无史源、V050 山无史山的第三族）；「鍾期」全库恰一处且在诗不在史——卷286 他人挽友「向秀初聞笛，鍾期久罷琴」（机器文件闭域断言，登记不引：它卷他人句不属本诗档案，V050 同卷语境不挪砝码纪律）——**典活在诗世界，死在史部**。
史部里倒是有「子期」，恰六处（机器断言处处前字必落「盧/破/擒」，全部集中在 tj-225/226）：田承嗣大将**盧子期**——大曆十年（乙卯，775）李宝臣等「大破子期於清水，擒子期至京師；斬之」（年标题窗口断言：775→776 之间），次年余波「及盧子期就擒，吳希光歸國」。
孟浩然開元末已卒（新传「開元末，病疽背卒」判例句不引，只作时距参照）——史部唯一的子期登场时，写这首诗的人已死三十多年。**被斩的叛将子期与诗里被想念的子期**并置是本层读法声明，不是史实。季节「夏日」如 V048 的重阳一样是「每到」不是「某年」。本层不铸时间。' AS body_text, 'SENIOR' AS audience, 'claim-bg-108-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-108-person' AS id, 'work-t300-108' AS work_id, 'PERSON' AS layer, '传里给这个人一句体面：新传「**張九齡、王維雅稱道之**」——当朝两位大人物齐声称扬他（新传单得：旧传孟段无「稱道」语，生成时机器断言；不合龙不升）。
把这句和诗对读：传里称扬他的张九龄、王维都是庙堂中人，诗里他半夜想念的却是一个连名都没传下来的辛大——**庙堂称扬与草堂想念**，同一位处士的两份清单。这是读法声明，不是史实；史实只有新传一句。判例零重开（audit 硬卡）：不才明主弃、放还、韩朝宗遑恤他、鹿门、孟亭、画浩然像、病疽背卒、樊泽刻碑，本层一个不引。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-108-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-108-scene' AS claim_id, 'source-ws-t300-108' AS source_id, '页面 夏日南亭懷辛大（header author+三段十句，四段以「……」相連——「山光忽西{{另|落|發}}」标记原样入引（页内异文照登，落/發不裁决，tang300-variants.md 新行）；同一 (claim,source) 主键一行容全文判例；正文另见 V018 claim-t300-108-text——本诗正文两度上限至此用满，后来者不得三引）' AS locator, '| author   = 孟浩然……山光忽西{{另|落|發}}，池月漸東上。散髮乘夕涼，開軒臥閑敞。……荷風送香氣，竹露滴清響。欲取鳴琴彈，恨無知音賞。……感此懷故人，中宵勞夢想。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-108-city' AS claim_id, 'source-ws-t300-108' AS source_id, '页面 夏日南亭懷辛大（header title 题内{{另|日|夕}}原样+页底注+分类行三段并收——题内异文（日/夕）系首见题面自带标记，照登不裁决（V044 反向极性）；底本指向与「仄韻五排」分类均为整理者动作：非史料声明、不升格（V048 分类行判例））' AS locator, '| title    = 夏{{另|日|夕}}南亭懷辛大……↑ [[全唐詩/卷159#夏日南亭懷辛大|全唐詩·卷159]]……[[Category:仄韻五排]]' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-108-city' AS claim_id, 'source-quantangshi-159' AS source_id, '卷一百五十九·孟浩然集两枚篇题锚点（本篇+《送辛大之鄂渚不及》——辛大四档之二；卷159 本迁移新立 source 行（V018 未立、V031 只立 160），辛大计数 8=4 锚点×2 结构为生成时机器断言）' AS locator, '==[[夏日南亭懷辛大]]==……==[[送辛大之鄂渚不及]]==' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-108-city' AS claim_id, 'source-quantangshi-160' AS source_id, '卷一百六十·孟浩然集两枚篇题锚点（《都下送辛大之鄂》+《張七及辛大見尋南亭醉作》——辛大四档之二；同一座南亭同一个辛大在本集另一首诗的门口；异衔的「辛大夫」六处（刘长卿唱和卷148 四处+卷151 二处）只登记在册不引——异衔不牵合）' AS locator, '==[[都下送辛大之鄂]]==……==[[張七及辛大見尋南亭醉作]]==' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-108-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷二百二十五·大曆十年条内卢子期破擒斩段……卷二百二十六复现摘句（通鉴「子期」恰六处全归此人——前字 {盧,破,擒}+文件闭域+年标题窗口三重机器断言；伯牙/鍾期通鉴全零为负证扫描；同名不同人不牵合；各单得不升）' AS locator, '李寶臣與昭義留後李承昭共救之，大破子期於清水，擒子期至京師；斬之。……及盧子期就擒，吳希光歸國' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-108-person' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零三·文藝下·孟浩然传雅称道句（张九龄王维齐声称扬——新传单得（旧传孟段无稱道语，生成时机器断言）；与诗中草堂想念的并置是读法声明）' AS locator, '張九齡、王維雅稱道之。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（十句：4/2/2/2） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-108-scene' AS background_id, 'text-work-t300-108-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-108-scene' AS background_id, 'text-work-t300-108-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-108-scene' AS background_id, 'text-work-t300-108-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-108-scene' AS background_id, 'text-work-t300-108-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-108-city' AS background_id, 'text-work-t300-108-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-108-city' AS background_id, 'text-work-t300-108-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-108-world' AS background_id, 'text-work-t300-108-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-108-world' AS background_id, 'text-work-t300-108-ws' AS version_id, 8 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-108-person' AS background_id, 'text-work-t300-108-ws' AS version_id, 9 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-108-person' AS background_id, 'text-work-t300-108-ws' AS version_id, 10 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 51, 'Meng Haoran Thinking of Brother Xin on a Summer Evening at the South Pavilion background layers (stage-D poem 32, ten-line five-character regulated sequence, first use of the 4/2/2/2 shape): dating verdict twenty-six, fourteenth shape of the title-evidence series -- the title keeps a season and a friend, yet the season is a recurring festival not a year (summer like the Double Ninth means every-autumn grammar) and the friend survives only as a family-ranking: Xin the Eldest is zero-count in both biographies of Meng while the Quantangshi keeps exactly four traces of the name, two title-anchors in juan 159 and two in juan 160 each counted twice by structure (machine 4x2 assertion, all four quoted verbatim) -- the man lives only in the poetry world, and lives busily there: seen off, missed, expected to stumble drunk at the same south pavilion; the zhiyin allusion has no archive even in names: Boya zero across both corpora, while the Tongjian''s six occurrences of Ziqi are machine-proven to belong wholly to the rebel general Lu Ziqi (prefix closure on the surname and capture verbs plus file closure on juan 225/226 plus a locked Dali-10 to 11 year-heading window) -- when history''s only Ziqi takes the stage the poet has been dead thirty years; titles of another poet''s Xin-the-Marshal poems are registered as same-surname-different-title and never cited (no weight moved); a first: the variant marker sits inside the title field itself (sun/evening), transcribed verbatim with its sibling marker on line one (double verbatim assertion); the new-history praise sentence (Zhang Jiuling and Wang Wei praised him highly) is single-source, the old history carrying no praise verb (machine-asserted) -- no agreement, no promotion; KNOWN zero honestly recorded (audit reverse-asserts); readings declared as readings; twelve closed precedent keywords stay out of citations; exactly one new source opened: the Quantangshi juan 159 (audit asserts the single INSERT)'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 51);
COMMIT;
