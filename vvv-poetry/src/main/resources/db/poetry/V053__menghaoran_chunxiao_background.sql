-- V053：孟浩然《春曉》(work-t300-121) 四层背景（阶段 D 第 34 首·异文有可核查出处首见）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V016、V018、V031、V037、V038、V051、V052 已执行（work-t300-121 与其
--       text-work-t300-121-ws、source-ws-t300-121 是 V018 的行；source-quantangshi-160 是 V031 的行；
--       source-quantangshi-283 是 V018、source-quantangshi-301 是 V027 的行；
--       source-jiutangshu-wenyuan 与 source-xintangshu-wenyi 是 V016 的行）。
--       **本迁移零新 source**（audit 断言 SQL 无任何诗源表新建插入语句）。
--
-- 数据源（可复现）：emit_v053.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/春曉__孟浩然_.txt（<ref> 实链×2 指四库本文苑英華卷0157、from 三本链、
--   底注又見卷160、Textquality|100%——异文有出处首见+底注第三形态），
--   全唐詩卷160（全卷唯一正文内联+内嵌 {{另}} 第三见证——快照内 {{另}} 首见）、
--   卷283/301（春曉聞鶯唱和题族册数）、舊唐書卷190下/新唐書卷203（孟段负证零入引）
--   + 通鑑 75 卷/全唐詩 120 卷负证计数扫描+既有迁移引文域逐句查重——
--   传区间归属、春曉/啼鳥全部计数、内联结构差异、传句用尽前提全部生成时断言。
--
-- 做：4 BACKGROUND content/claim/background + 6 组逐字引用（(claim,source) 主键每对恰一行）+
--   4 行 background_line（四句绝句形制：scene→1 city→2 world→3 person→4，
--   绑 text-work-t300-121-ws 的 4 行）。本迁移不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下；
--   **零传句入引**（传句用尽，PERSON 层只读版本目录链——见下）。
--
-- 诚实边界（这首的边界是「題有節候無年份，詩有三本無一家」）：
--   * 异文有可核查出处首见：<ref> 不是笼统「一本作」而是实链四库本《文苑英華》卷0157——
--     「每句史实有可核查出处」在异文层首次落地；两支 witness（<ref>/卷160 内联 {{另}}）
--     照登不裁决、各自完整保留不合并（audit 双断言硬卡两处标记字样）；
--   * 卷160 结构差异机器断言：本篇消歧锚点恰一+转引桩零=全卷唯一正文内联；
--   * 同题族不牵合：春曉聞鶯（李益奉和/王建再和）在册入引锚点、正文零引、不牵合孟诗；
--   * 通鉴春曉/啼鳥/聞啼鳥全零：家喻户晓零档案（机器负证，本层零入引只做声明）；
--   * 传句用尽首见：孟传十一句全在 V016/V031/V037/V038 入引（生成时逐句查重硬卡），
--     本迁移零传句——再引即重开判例；from 三本链=版本目录链（非史料声明，locator 硬卡）；
--   * KNOWN 零如实记录（第九例，audit 反向断言 SQL 无 KNOWN 字面量）；
--   * 苏醒过程/惜花读法/「书架就是它的传记」均为读法声明；
--   * 不才明主弃/放還/韓朝宗/遑恤他/鹿門/孟亭/刻碑鳳林山南/雅稱道之/知音/南亭 判例只引不重开。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 52，不含 53
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-121-%';             -- 空
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-121-ws';  -- 恰 4（绝句）
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-121-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-121';                                  -- 4（1/1/1/1）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-121-%';  -- 四行全 LIKELY（有意全 LIKELY）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-121'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-121';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-121-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
--   SELECT COUNT(*) FROM poetry_source WHERE id='source-ws-t300-121';   -- 恰 1（V018 旧行，零新源）
-- 回滚: recovery/V053_rollback.sql（按 id 全枚举删除；不动任何共用来源行、不动 V018 的行）
START TRANSACTION;

-- ---------- 1. BACKGROUND content identities（零新 source——断言在生成器 audit） ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-121-scene' AS id, 'BACKGROUND' AS entity_type, '121-scene' AS slug, '眼前：一个春天的苏醒' AS title, '四层处境背景（阶段 D 第 34 首·四句绝句 1/1/1/1 形制）；史实句均有逐字引证；系年第二十八次判决「題有節候無年份，詩有三本無一家」（题证系列第十六状·四库实链与馆藏谱系——「春曉」是节气感不是年份（周期时间第三例：重阳/夏日/春曉），而版本谱系可列书架：from 三本（文苑英華四库本卷0157/唐音四库本卷06/四部丛刊孟浩然集 djvu121）+又見卷160+<ref> 钉回卷0157——三本各有其字谁也没吃掉谁）→time.span/event.name/written_during 全缺席、零 relation；异文有可核查出处首见：<ref> 实链具体卷次（V049 无实链→本迁移实链首见）；全唐詩快照内 {{另}} 首见：卷160 本篇全卷唯一正文内联（锚点一桩零结构断言）+内嵌第三见证与 ws <ref> 互证同支、两支 witness 不合并（audit 双断言硬卡）；同题族不牵合：春曉聞鶯唱和两家（卷283/301）在册不引；通鉴春曉/啼鳥/聞啼鳥全零（家喻户晓零档案，机器负证）；传句用尽首见：孟传十一句全在 V016/V031/V037/V038 入引（生成时逐句查重硬卡）→PERSON 层零传句、只读版本目录（非史料声明硬卡）；KNOWN 零如实记录（audit 反向断言）；零新 source；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-121-city' AS id, 'BACKGROUND' AS entity_type, '121-city' AS slug, '这座城：一支诗的两支见证与一个书架' AS title, '四层处境背景（阶段 D 第 34 首·四句绝句 1/1/1/1 形制）；史实句均有逐字引证；系年第二十八次判决「題有節候無年份，詩有三本無一家」（题证系列第十六状·四库实链与馆藏谱系——「春曉」是节气感不是年份（周期时间第三例：重阳/夏日/春曉），而版本谱系可列书架：from 三本（文苑英華四库本卷0157/唐音四库本卷06/四部丛刊孟浩然集 djvu121）+又見卷160+<ref> 钉回卷0157——三本各有其字谁也没吃掉谁）→time.span/event.name/written_during 全缺席、零 relation；异文有可核查出处首见：<ref> 实链具体卷次（V049 无实链→本迁移实链首见）；全唐詩快照内 {{另}} 首见：卷160 本篇全卷唯一正文内联（锚点一桩零结构断言）+内嵌第三见证与 ws <ref> 互证同支、两支 witness 不合并（audit 双断言硬卡）；同题族不牵合：春曉聞鶯唱和两家（卷283/301）在册不引；通鉴春曉/啼鳥/聞啼鳥全零（家喻户晓零档案，机器负证）；传句用尽首见：孟传十一句全在 V016/V031/V037/V038 入引（生成时逐句查重硬卡）→PERSON 层零传句、只读版本目录（非史料声明硬卡）；KNOWN 零如实记录（audit 反向断言）；零新 source；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-121-world' AS id, 'BACKGROUND' AS entity_type, '121-world' AS slug, '这个天下：史部没有的一秒' AS title, '四层处境背景（阶段 D 第 34 首·四句绝句 1/1/1/1 形制）；史实句均有逐字引证；系年第二十八次判决「題有節候無年份，詩有三本無一家」（题证系列第十六状·四库实链与馆藏谱系——「春曉」是节气感不是年份（周期时间第三例：重阳/夏日/春曉），而版本谱系可列书架：from 三本（文苑英華四库本卷0157/唐音四库本卷06/四部丛刊孟浩然集 djvu121）+又見卷160+<ref> 钉回卷0157——三本各有其字谁也没吃掉谁）→time.span/event.name/written_during 全缺席、零 relation；异文有可核查出处首见：<ref> 实链具体卷次（V049 无实链→本迁移实链首见）；全唐詩快照内 {{另}} 首见：卷160 本篇全卷唯一正文内联（锚点一桩零结构断言）+内嵌第三见证与 ws <ref> 互证同支、两支 witness 不合并（audit 双断言硬卡）；同题族不牵合：春曉聞鶯唱和两家（卷283/301）在册不引；通鉴春曉/啼鳥/聞啼鳥全零（家喻户晓零档案，机器负证）；传句用尽首见：孟传十一句全在 V016/V031/V037/V038 入引（生成时逐句查重硬卡）→PERSON 层零传句、只读版本目录（非史料声明硬卡）；KNOWN 零如实记录（audit 反向断言）；零新 source；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-121-person' AS id, 'BACKGROUND' AS entity_type, '121-person' AS slug, '这个人：传句用尽，书架接任' AS title, '四层处境背景（阶段 D 第 34 首·四句绝句 1/1/1/1 形制）；史实句均有逐字引证；系年第二十八次判决「題有節候無年份，詩有三本無一家」（题证系列第十六状·四库实链与馆藏谱系——「春曉」是节气感不是年份（周期时间第三例：重阳/夏日/春曉），而版本谱系可列书架：from 三本（文苑英華四库本卷0157/唐音四库本卷06/四部丛刊孟浩然集 djvu121）+又見卷160+<ref> 钉回卷0157——三本各有其字谁也没吃掉谁）→time.span/event.name/written_during 全缺席、零 relation；异文有可核查出处首见：<ref> 实链具体卷次（V049 无实链→本迁移实链首见）；全唐詩快照内 {{另}} 首见：卷160 本篇全卷唯一正文内联（锚点一桩零结构断言）+内嵌第三见证与 ws <ref> 互证同支、两支 witness 不合并（audit 双断言硬卡）；同题族不牵合：春曉聞鶯唱和两家（卷283/301）在册不引；通鉴春曉/啼鳥/聞啼鳥全零（家喻户晓零档案，机器负证）；传句用尽首见：孟传十一句全在 V016/V031/V037/V038 入引（生成时逐句查重硬卡）→PERSON 层零传句、只读版本目录（非史料声明硬卡）；KNOWN 零如实记录（audit 反向断言）；零新 source；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-121-scene' AS id, 'bg-121-scene' AS subject_id, 'context' AS property_key, '四句全诗本文（ws 页 {{Textquality|100%}}+两枚 <ref> 实链原样入引——异文有可核查出处首见（V049 <ref> 无实链→本迁移实链首见），audit 照登断言硬卡两枚 <ref> 字样；同一 (claim,source) 主键一行容全文判例；正文另见 V018 claim-t300-121-text——本诗正文两度上限至此用满，后来者不得三引）；通鉴春曉/啼鳥/聞啼鳥全零为负证扫描；苏醒过程与惜花读法为本层声明，非史料断言。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-121-city' AS id, 'bg-121-city' AS subject_id, 'context' AS property_key, '书架档案：底注「又見全唐詩/卷160」照登（底注第三形态）+非史料声明+不升格；卷160 结构差异机器断言：本篇消歧锚点恰一+转引桩零=全卷唯一正文内联；内嵌 {{另}} 第三见证逐字入引（全唐詩快照内 {{另}} 首见，audit 双断言硬卡），与 ws <ref> 互证同支、两支 witness 不合并（异文照登不裁决）；同题族不牵合：「春曉聞鶯」唱和两家（卷283 李益/卷301 王建）锚点逐字入册，与孟诗无涉不牵合（V051 异衔/V052 同名异地之后第三形态）；题有節候無年份→零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-121-world' AS id, 'bg-121-world' AS subject_id, 'context' AS property_key, '周期时间第三例（重阳/夏日/春曉——每到不是某年）；通鉴「春曉」「啼鳥」「聞啼鳥」计数全零（机器负证扫描——家喻户晓零档案）；诗语与唱和题族均不构成孟诗语境（V049 同卷语境不挪砝码延伸）；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-121-person' AS id, 'bg-121-person' AS subject_id, 'context' AS property_key, '传句用尽（首见）：孟传十一句候选全部已在 V016/V031/V037/V038 入引（生成时逐句全库引文域查重机器断言）——本迁移零传句入引，再引即重开判例；PERSON 层只读版本目录：from 三本链逐字入引（四库本文苑英華卷0157/四库本唐音卷06/四部丛刊孟浩然集 djvu121 页）——版本目录链非史料断言（audit locator 硬卡），说的是流传不是写作；「书架就是它的传记」为读法声明；判例零重开。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-121-scene' AS subject_id, 'context' AS property_key, 'claim-bg-121-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-121-city' AS subject_id, 'context' AS property_key, 'claim-bg-121-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-121-world' AS subject_id, 'context' AS property_key, 'claim-bg-121-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-121-person' AS subject_id, 'context' AS property_key, 'claim-bg-121-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-121-scene' AS id, 'work-t300-121' AS work_id, 'SCENE' AS layer, '二十个字是一个早晨的完整苏醒：春睡得沉，不知不觉天亮了（「春眠不覺曉」——醒来的第一个念头是「已经天亮」）；醒来先听见的是鸟，到处都是（「處處聞啼鳥」——听觉先于视觉）；想起夜里的风雨声（「夜來風雨聲」——页内 <ref> 实链四库本《文苑英華》卷0157 作「欲知昨夜風」，异文有可核查出处首见，照登不裁决），那些花被打落了多少呢（「花落知」——同枚 <ref> 注「一作無」）多少——问题悬在问句上收束。通鉴 75 卷里「春曉」「啼鳥」一个字符都没有（机器断言）：最家喻户晓的二十字，史部零档案。醒来惜花的读法是本层声明，史实只有页上四句。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-121-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-121-city' AS id, 'work-t300-121' AS work_id, 'CITY' AS layer, '这首诗的「城」是一座书架。底注「又見[[全唐詩/卷160]]」是整理者的跨卷又見注（底注第三形态：既非底本指向、也非「一作某某詩」——非史料声明、不升格）。卷160 的全唐詩快照里，本篇是**全卷唯一正文内联**：他篇皆是「篇题锚点+转引桩」（V049/V050/V051 三验），唯独《春曉》锚点后直接内嵌正文，且内嵌第三见证「{{另|夜來風雨聲，花落知多少|欲知昨夜風，花落無多少}}」（全唐詩快照内 {{另}} 标记首见，audit 照登硬卡）——它与 ws 页 <ref>「《文苑英華》作欲知昨夜風」**互证同支**：两个体系各自完整保留两支 witness，没有一处合并（异文照登纪律最完整的一页）。另登记在册、与孟诗无涉：全唐詩「春曉」恰五处，余三处是「春曉聞鶯」唱和题族（卷283 李益《奉和武相公春曉聞鶯》+卷301 王建《和門下武相公春曉聞鶯》）——同名题族不牵合（V051 异衔/V052 同名异地之后的**同题族不牵合**）。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-121-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-121-world' AS id, 'work-t300-121' AS work_id, 'WORLD' AS layer, '「春曉」是节气感不是年份——V048 重阳、V051 夏日之后第三枚周期时间：每个春天都这样醒一次，所以系不了年（判决在文件头）。史部侧本层只做负证：通鉴 75 卷「春曉」「啼鳥」「聞啼鳥」计数全零（机器断言）——这首诗在史部没有一秒的档案，它的全部档案都在诗世界与书架上。「唱和题族在册不引」是负证的延伸：同名句在史部与诗世界都不构成孟诗的语境（同卷语境不挪砝码，V049 纪律）。本层零铸造零 relation。' AS body_text, 'SENIOR' AS audience, 'claim-bg-121-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-121-person' AS id, 'work-t300-121' AS work_id, 'PERSON' AS layer, '这个人的传，本迁移**一个传字都不引**——生成时全库引文域逐句查重：孟浩然两传十一句候选（少好節義/喜振人患難/以詩自適/署為從事/與之唱和/應進士不第/不逹而卒/隱鹿門山/病疽背卒/同知名者/皆位不顯）全部已在 V016/V031/V037/V038 入引（机器断言在册）——传已讲完，再引就是重开判例。那「凭什么传」？版本目录给答案：from 三本——《文苑英華》四庫全書本卷0157、《唐音》四庫全書本卷06、《孟浩然集》四部叢刊本影印 djvu 第 121 页（页内链原样入引）；再加上全唐詩卷160 的又見注。**一首二十字的绝句，被四部书各抄了一遍**——书架就是它的传记。from 链是版本目录链（非史料断言，audit locator 硬卡），它说的是流传，不是写作。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-121-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-121-scene' AS claim_id, 'source-ws-t300-121' AS source_id, '页面 春曉 (孟浩然)（header author+四句，三行以「……」相連——第3句含两枚 <ref> 实链《文苑英華 (四庫全書本)/卷0157》原样入引（异文有可核查出处首见：欲知昨夜風/一作無，照登不裁决，tang300-variants.md 新行）；同一 (claim,source) 主键一行容全文判例；正文另见 V018 claim-t300-121-text——本诗正文两度上限至此用满，后来者不得三引）' AS locator, '| author   = 孟浩然……春眠不覺曉，處處聞啼鳥。……夜來風雨聲<ref>《[[文苑英華 (四庫全書本)/卷0157|文苑英華]]》作「欲知昨夜風」</ref>，花落知<ref>《[[文苑英華 (四庫全書本)/卷0157|文苑英華]]》：「一作無」</ref>多少。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-121-city' AS claim_id, 'source-ws-t300-121' AS source_id, '页面 春曉 (孟浩然)（notes 又見注+type2/theme2 分类两行+Category 三段并收——底注「又見全唐詩/卷160」系跨卷又見（底注第三形态：非底本指向、非一作某某詩）；五言絕句/詠春詩/千家詩均为整理者分类动作：非史料声明、不升格（V048 分类行判例）；header title 消歧链 [[春曉]] 原样并收——与 V018 作品题一致，不另作异文）' AS locator, '| title    = [[春曉]]……| notes    ={{Textquality|100%}}{{-|又見[[全唐詩/卷160]]}}……| type2    = 五言絕句
| theme    = 唐詩
| theme2   = 詠春詩……[[Category:千家詩]]' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-121-city' AS claim_id, 'source-quantangshi-160' AS source_id, '卷一百六十·孟浩然集《春曉 (孟浩然)》正文内联段（消歧篇题锚点+内嵌 {{另}} 第三见证两段并收——全卷唯一正文内联（其余各篇锚点×2 转引桩结构，本篇锚点一+桩零，生成时机器结构差异断言）；内联 {{另}} 系全唐詩快照内 {{另}} 标记首见，与 ws 页 <ref> 互证同支——两支 witness 各自完整保留不合并）' AS locator, '==[[春曉 (孟浩然)|春曉]]==……{{另|夜來風雨聲，花落知多少|欲知昨夜風，花落無多少}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-121-city' AS claim_id, 'source-quantangshi-283' AS source_id, '卷二百八十三·李益《奉和武相公春曉聞鶯》篇题锚点（「春曉聞鶯」唱和题族之一——同名题族在册不引正文：与孟诗无涉不牵合，V051 异衔/V052 同名异地第三形态；全唐詩「春曉」恰 5=160×1+283×2+301×1 生成时计数断言）' AS locator, '==[[奉和武相公春曉聞鶯]]==' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-121-city' AS claim_id, 'source-quantangshi-301' AS source_id, '卷三百零一·王建《和門下武相公春曉聞鶯》目录行（唱和题族之二——李益奉和、王建再和，武相公为唱和主场而孟浩然不在其中；册数断言见 283 locator）' AS locator, '《和門下武相公春曉聞鶯》王建' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-121-person' AS claim_id, 'source-ws-t300-121' AS source_id, '页面 春曉 (孟浩然)（header from 三本链整段入引——版本目录链，非史料断言：四庫全書本文苑英華卷0157+四庫全書本唐音卷06+四部叢刊本孟浩然集 djvu 第121页；「凭什么传」的书架答案；传句用尽：十一句候选全在 V016/V031/V037/V038 入引，本迁移零传句——audit 生成时逐句查重硬卡）' AS locator, '| from     = 文苑英華 (四庫全書本)/卷0157
| from2    = 唐音 (四庫全書本)/卷06
| from3    = 页面:Sibu Congkan0646-孟浩然-孟浩然集-1-1.djvu/121{{!}}孟浩然集 (四部叢刊本)' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（四句绝句：1/1/1/1） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-121-scene' AS background_id, 'text-work-t300-121-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-121-city' AS background_id, 'text-work-t300-121-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-121-world' AS background_id, 'text-work-t300-121-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-121-person' AS background_id, 'text-work-t300-121-ws' AS version_id, 4 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 53, 'Meng Haoran Spring Dawn background layers (stage-D poem 34, four-line quatrain 1/1/1/1, first time a variant carries a checkable citation): dating verdict twenty-eight, sixteenth shape of the title-evidence series -- the title keeps a season-feeling not a year (third cyclic time after Double Ninth and summer day) while the poem keeps three books and no single family: the page''s <ref> notes are live links into the Siku Wenyuan Yinghua juan 157 (so the variant "欲知昨夜風" and "一作無" can be opened and checked -- the goal "every historical sentence has a verifiable source" lands on the variant layer for the first time), the from-fields list three shelves (Siku Wenyuan Yinghua 157, Siku Tangyin 6, Sibu Congkan Meng Haoran ji djvu page 121) and the note adds a cross-volume "also seen in Quantangshi juan 160"; in juan 160 this poem is the volume''s only inline text (machine structure assertion: one disambiguated anchor, zero transclusion stubs) embedding a third witness marker {{另}} -- the first {{另}} anywhere in the Quantangshi snapshot -- corroborating the ws <ref> branch, both witnesses preserved whole, never merged (audit double hard-assert); same-title-family no-conflation: the Chunxiao Wenying唱和 pair in juan 283/301 catalogued by anchor only, prose never quoted, never read as Meng''s context; Tongjian counts of 春曉/啼鳥/聞啼鳥 are all zero -- the most memorized twenty characters in China hold zero archive in history (machine negative); precedent exhaustion first appearance: all eleven candidate biography sentences of Meng were already cited in V016/V031/V037/V038 (generated-time per-sentence sweep hard-assert), so this migration quotes zero biography lines and PERSON reads only the bibliographic chain (declared non-historical in locator); KNOWN zero honestly recorded (ninth instance, audit reverse-asserts); zero new sources (six shared source rows pre-exist, audit asserts no source-row insert statement); closed precedent keywords stay out of citations'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 53);
COMMIT;
