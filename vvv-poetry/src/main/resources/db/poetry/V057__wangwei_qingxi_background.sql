-- V057：王維《青谿》(work-t300-056) 四层背景（阶段 D 第 38 首·贡道与撞字）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V014、V015、V016、V018、V035、V037、V056 已执行（work-t300-056 与其
--       text-work-t300-056-ws、source-ws-t300-056 是 V018 的行；source-quantangshi-125 是 V035 的行；
--       source-jiutangshu-wenyuan/source-xintangshu-wenyi 是 V016 的行；
--       source-zizhi-tongjian-events 是 V014/V015 已立的通鉴事件源）。
--       **本迁移零新 source**（audit 断言 SQL 无任何诗源表新建插入语句）。
--
-- 数据源（可复现）：emit_v057.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/青谿.txt（「一名「過青谿水作」」一名式异名注首见+四标记全零×75% 正交再验）、
--   舊唐書卷190下（居母丧柴毁句首引+王维段负证）、新唐書卷202（母丧毁几不生句首引+负证）、
--   通鑑卷249（青溪唯一一处开道+大中十三年窗口+「初」字追书边界）+
--   通鑑 75 卷/全唐詩 118 卷存快照负证计数扫描（青谿/青溪/已矣前字/亂石/深松/垂釣/黃花川）+
--   既有迁移引文域逐句查重——传区间归属、首引前提与第二引前提全部生成时断言。
--
-- 做：4 BACKGROUND content/claim/background + 6 组逐字引用（(claim,source) 主键每对恰一行）+
--   12 行 background_line（十二句形制：scene→1-4 city→5-6 world→7-10 person→11-12，
--   绑 text-work-t300-056-ws 的 12 行）。本迁移不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「題有谿名，谿在史部止一開道；詩收已矣，已矣在史部只而已矣」）：
--   * 青谿通鉴全零+青溪恰一处=贡道（闭域+窗口断言）；「初」字追书：窗口年=入书年非事件年；
--   * 已矣撞字两界：通鉴恰二皆「而已矣」（前字必而机器断言），诗之决志在册零入引；
--   * 本诗正文第二引上限用满：V018 一引在先（全库查重恰一处），对后来迁移关闭；
--   * 「一名「過青谿水作」」照登硬卡+异题快照零命中如实登记不改题；
--   * 两传母丧异词句并置首引（合而不并首见，audit 双硬卡）；
--   * 心川对写/閒毁并置均为读法声明，audit 双声明在 BG 文本内；
--   * KNOWN 零如实记录（第十三例，audit 反向断言 SQL 无 KNOWN 字面量）；
--   * 不才/凝碧/輞川/藍田/茶鐺/尤長五言/以詩名盛/事母崔氏/齋中四物 判例只引不重开。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 56，不含 57
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-056-%';             -- 空
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-056-ws';  -- 恰 12
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-056-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-056';                                  -- 12（4/2/4/2）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-056-%';  -- 四行全 LIKELY（有意全 LIKELY）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-056'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-056';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-056-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
--   SELECT COUNT(*) FROM poetry_source WHERE id='source-ws-t300-056';   -- 恰 1（V018 旧行，零新源）
-- 回滚: recovery/V057_rollback.sql（按 id 全枚举删除；不动任何共用来源行、不动 V018 的行）
START TRANSACTION;

-- ---------- 1. BACKGROUND content identities（零新 source——断言在生成器 audit） ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-056-scene' AS id, 'BACKGROUND' AS entity_type, '056-scene' AS slug, '眼前：随山万转的这条水' AS title, '四层处境背景（阶段 D 第 38 首·十二句五古 4/2/4/2 形制首用）；史实句均有逐字引证；系年第三十二次判决（题证系列第二十状·贡道与撞字）「題有谿名，谿在史部止一開道；詩收已矣，已矣在史部只而已矣」——通鉴「青谿」全零、「青溪」恰一处=大中十三年（己卯，八五九）窗口追书「開青溪道以通群蠻」（闭域+年窗口断言；「初」字追书边界：窗口年系入书年非事件年，如实声明不据以系事）；通鉴「已矣」恰二皆「而已矣」语气（前字必而机器断言）——诗之决志与史之语气撞字两界，在册零入引（V056 泪两界第二形态）；「一名「過青谿水作」」纯文本一名式异名注首见（audit 照登硬卡；异题快照零命中如实登记不改题）；零标记×75% 正交再验；本诗正文第二引上限用满对后来关闭（V018 在先+全库查重）；两传母丧异词句并置首引（合而不并首见，V037 合龙反向操作，audit 双硬卡）；KNOWN 零如实记录（第十三例，audit 反向断言）；零新 source；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-056-city' AS id, 'BACKGROUND' AS entity_type, '056-city' AS slug, '这座城：底注第二行的另一个名字' AS title, '四层处境背景（阶段 D 第 38 首·十二句五古 4/2/4/2 形制首用）；史实句均有逐字引证；系年第三十二次判决（题证系列第二十状·贡道与撞字）「題有谿名，谿在史部止一開道；詩收已矣，已矣在史部只而已矣」——通鉴「青谿」全零、「青溪」恰一处=大中十三年（己卯，八五九）窗口追书「開青溪道以通群蠻」（闭域+年窗口断言；「初」字追书边界：窗口年系入书年非事件年，如实声明不据以系事）；通鉴「已矣」恰二皆「而已矣」语气（前字必而机器断言）——诗之决志与史之语气撞字两界，在册零入引（V056 泪两界第二形态）；「一名「過青谿水作」」纯文本一名式异名注首见（audit 照登硬卡；异题快照零命中如实登记不改题）；零标记×75% 正交再验；本诗正文第二引上限用满对后来关闭（V018 在先+全库查重）；两传母丧异词句并置首引（合而不并首见，V037 合龙反向操作，audit 双硬卡）；KNOWN 零如实记录（第十三例，audit 反向断言）；零新 source；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-056-world' AS id, 'BACKGROUND' AS entity_type, '056-world' AS slug, '这个天下：青溪在史部是一条贡道' AS title, '四层处境背景（阶段 D 第 38 首·十二句五古 4/2/4/2 形制首用）；史实句均有逐字引证；系年第三十二次判决（题证系列第二十状·贡道与撞字）「題有谿名，谿在史部止一開道；詩收已矣，已矣在史部只而已矣」——通鉴「青谿」全零、「青溪」恰一处=大中十三年（己卯，八五九）窗口追书「開青溪道以通群蠻」（闭域+年窗口断言；「初」字追书边界：窗口年系入书年非事件年，如实声明不据以系事）；通鉴「已矣」恰二皆「而已矣」语气（前字必而机器断言）——诗之决志与史之语气撞字两界，在册零入引（V056 泪两界第二形态）；「一名「過青谿水作」」纯文本一名式异名注首见（audit 照登硬卡；异题快照零命中如实登记不改题）；零标记×75% 正交再验；本诗正文第二引上限用满对后来关闭（V018 在先+全库查重）；两传母丧异词句并置首引（合而不并首见，V037 合龙反向操作，audit 双硬卡）；KNOWN 零如实记录（第十三例，audit 反向断言）；零新 source；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-056-person' AS id, 'BACKGROUND' AS entity_type, '056-person' AS slug, '这个人：诗里的心素閒，传里的毁骨立' AS title, '四层处境背景（阶段 D 第 38 首·十二句五古 4/2/4/2 形制首用）；史实句均有逐字引证；系年第三十二次判决（题证系列第二十状·贡道与撞字）「題有谿名，谿在史部止一開道；詩收已矣，已矣在史部只而已矣」——通鉴「青谿」全零、「青溪」恰一处=大中十三年（己卯，八五九）窗口追书「開青溪道以通群蠻」（闭域+年窗口断言；「初」字追书边界：窗口年系入书年非事件年，如实声明不据以系事）；通鉴「已矣」恰二皆「而已矣」语气（前字必而机器断言）——诗之决志与史之语气撞字两界，在册零入引（V056 泪两界第二形态）；「一名「過青谿水作」」纯文本一名式异名注首见（audit 照登硬卡；异题快照零命中如实登记不改题）；零标记×75% 正交再验；本诗正文第二引上限用满对后来关闭（V018 在先+全库查重）；两传母丧异词句并置首引（合而不并首见，V037 合龙反向操作，audit 双硬卡）；KNOWN 零如实记录（第十三例，audit 反向断言）；零新 source；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-056-scene' AS id, 'bg-056-scene' AS subject_id, 'context' AS property_key, '十二句全诗本文（ws 页四标记全零、Textquality 75%——零标记与不完备并存，V055 正交横截面再验）；末联「請留盤石上，垂釣將已矣」系第二引：正文 V018 text claim 一引在先（生成时全库查重恰一处），两度上限至此用满、此诗正文对后来迁移关闭（audit 硬卡）；心川对写与决志读法系本层声明非史料断言。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-056-city' AS id, 'bg-056-city' AS subject_id, 'context' AS property_key, '「一名」式异名注首见：底注第二行「一名「過青谿水作」」纯文本无标记（V052/V055 纯文本二式之后第三式），逐字入引 audit 照登硬卡，登记不裁决；异题「過青谿水」快照零命中（机器断言）——异题无凭如实登记不改题；页四标记全零而 75%（正交再验）；分类行照登+非史料声明+不升格；卷125 无消歧锚+桩（各恰一）；全唐詩「青谿」恰 2 唯本篇、邻体「青溪」恰 11 处他卷在册不引（谿/溪字样异写）；题有溪而无时→零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-056-world' AS id, 'bg-056-world' AS subject_id, 'context' AS property_key, '溪在史部止一开道：通鉴「青谿」全零+「青溪」恰 1 处=tj-249 大中十三年（己卯，八五九）窗口追书「開青溪道以通群蠻」（文件闭域+年标题窗口机器断言）；**「初」字追书边界**：窗口年系入书年非事件年，本迁移不据以系任何事（audit 声明）；撞字两界第二形态：通鉴「已矣」恰 2 皆「而已矣」语气（tj-192，机器断言前字必而），诗之决志语在册零入引；诗语亂石/深松/垂釣/黃花川通鉴全零；两传王维段青谿/青溪/垂釣全零；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-056-person' AS id, 'bg-056-person' AS subject_id, 'context' AS property_key, '两传同事异词句并置首引（V037 两源合龙的反向操作「合而不并」首见）：旧传「居母䘮，柴毁骨立，殆不勝䘮」旧传单得、新传「母喪，毀幾不生」新传单得（生成时全库引文域查重：两句既往零命中，audit 双硬卡；各自逐字入引、词异不合并）；閒与毁并置为读法声明非史实；王维其余已用判例句零重开；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-056-scene' AS subject_id, 'context' AS property_key, 'claim-bg-056-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-056-city' AS subject_id, 'context' AS property_key, 'claim-bg-056-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-056-world' AS subject_id, 'context' AS property_key, 'claim-bg-056-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-056-person' AS subject_id, 'context' AS property_key, 'claim-bg-056-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-056-scene' AS id, 'work-t300-056' AS work_id, 'SCENE' AS layer, '十二句是一段顺着水走的行程：说进黄花川，就常常沿着青谿水走（「言入黃花川，每逐青谿水」）；山随人转将近万道，途程不满百里（「隨山將萬轉，趣途無百里」）；水声在乱石中喧响，青色在深松里安静（「聲喧亂石中，色靜深松裏」——喧与静各占半句）；菱荇漾漾地浮过，葭葦澄澄地映水（「漾漾泛菱荇，澄澄映葭葦」）。收束把心交出去：「我心素已閒，清川澹如此」——心本來就閒，正如这条川淡；「請留盤石上，垂釣將已矣」——此末联系**第二引**（正文 V018 text claim 一引在先，全库查重恰一处），两度上限至此用满，此诗正文对后来迁移关闭。「已矣」二字收的是决志；心与川互为譬喻是页上原文的对写，不是史实。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-056-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-056-city' AS id, 'work-t300-056' AS work_id, 'CITY' AS layer, '这条城的档案先登记另一个题目：页底注第二行「一名「過青谿水作」」——「青谿／過青谿水作」两名并挂，**纯文本无标记**（V052 纯文本署名异说、V055 「川一作水」底注尾巴之后**「一名」式异名注首见**——整短语挂底注第二行，audit 硬卡字样），照登不裁决；且异题「過青谿水」在全唐詩快照**零命中**（机器断言）：这条异题支在存卷里无凭，如实登记而不据以改题。页 {{另}}/{{别}}/{{*}}/<ref> 四全零而 Textquality 只有 75%——V055 的零标记×75% 正交横截面在此再验一次（机器断言）。分类行「五言古詩」为整理者动作：照登+非史料声明+不升格（V048 判例）。卷125 本篇为「无消歧篇题锚点+转引桩」结构（同 V055，机器断言各恰一）。谿字题族唯本篇：全唐詩「青谿」恰 2=锚+桩；邻体「青溪」11 处（谿/溪系字样异写）分布他卷各是各诗，在册不引不牵合。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-056-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-056-world' AS id, 'work-t300-056' AS work_id, 'WORLD' AS layer, '题面这条溪，史部只记过一件开路的事：通鉴「青谿」（这个「谿」字）75 卷**全零**；「青溪」恰一处（文件闭域+年标题窗口机器断言）——大中十三年（己卯，八五九）窗口内：「初，韋皋在西川，開青溪道以通群蠻，使由蜀入貢」。**史部的青溪是一条贡使走的路**。
**「初」字追书新边界（如实声明）**：通鉴以「初」字在八五九年窗口里追记德宗朝旧事——年窗口锁的是这段文字入书的位置，不是事件发生的年份；V034 立的窗口断言只证文本位置，本迁移不据以系任何事（audit 声明在册）。
诗的收束「垂釣將已矣」；通鉴「已矣」恰二处却都不算数——两处皆「…而已矣」句末语气（tj-192 论规矩礼乐，机器断言二处前字必「而」）：「已矣」在诗里是决志、在史部是语气——**撞字两界，在册零入引**（V056 泪两界之后的第二形态）。诗语「亂石」「深松」「垂釣」「黃花川」通鉴亦全零。**溪在史部止一開道，已矣在史部只而已矣**；本层零铸造零 relation。' AS body_text, 'SENIOR' AS audience, 'claim-bg-056-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-056-person' AS id, 'work-t300-056' AS work_id, 'PERSON' AS layer, '诗的收束是「我心素已閒」；两部史书写到这个人守母丧时，用的却是最不吃得消的字。旧传：「**居母䘮，柴毁骨立，殆不勝䘮。**」（居母丧，毁瘠骨立，几乎撑不过丧期）；新传：「**母喪，毀幾不生。**」（母丧，毁顿几乎活不成）——**同一件事，两部书两种措辞**（生成时全库查重：两句既往零入引，本迁移并置首引；旧传单得、新传单得，各自逐字入引，**并列不合并**——「V037 两源合龙」的反向操作：事同一而词各各，合而不并，audit 双硬卡）。
把閒与毁并置看：诗里的心「素已閒」，传里的人毁到骨立——同一个人的两种时刻，并置是读法声明非史实。王维传其余已用句（以詩名盛/凝碧/輞川/茶鐺/奉佛段/尤長五言/事母崔氏以孝聞 V055 首引/齋中四物 V054 首引）一个不重开；两传王维段「青谿」「青溪」「垂釣」全零（机器断言）——传写其人，不提这条溪。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-056-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-056-scene' AS claim_id, 'source-ws-t300-056' AS source_id, '页面 青谿（header author+六联十二句，四段以「……」相連——末联「請留盤石上，垂釣將已矣」**第二引**：正文 V018 text claim 一引在先、本迁移取末联二引，**两度上限至此用满，此诗正文对后来迁移关闭**（生成时全库查重恰一处=V018）；页四标记全零、75%（正交再验）' AS locator, '| author   = 王維……言入黃花川，每逐青谿水。
隨山將萬轉，趣途無百里。……聲喧亂石中，色靜深松裏。
漾漾泛菱荇，澄澄映葭葦。……我心素已閒，清川澹如此。
請留盤石上，垂釣將已矣。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-056-city' AS claim_id, 'source-ws-t300-056' AS source_id, '页面 青谿（header title+页底注+分类行三段并收——底注第二行「一名「過青谿水作」」系**「一名」式异名注首见**（纯文本第三式，audit 硬卡字样照登不裁决；异题快照零命中如实登记）；「五言古詩」分类系整理者动作：非史料声明、不升格；页 {{另}}/{{别}}/{{*}}/<ref> 全零而 75%）' AS locator, '| title    = 青谿……| notes    = {{Textquality|75%}}↑ [[全唐詩/卷125#青谿|全唐詩·卷125]]
一名「過青谿水作」……[[Category:五言古詩]]' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-056-city' AS claim_id, 'source-quantangshi-125' AS source_id, '卷一百二十五·王维集《青谿》篇题锚点+转引桩（无消歧直锚——机器断言锚桩各恰一；全唐詩「青谿」恰 2 即此二处，邻体「青溪」恰 11 处他卷在册不引——谿/溪字样异写）' AS locator, '==[[青谿]]==……{{:青谿}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-056-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷二百四十九·大中十三年（己卯，八五九）窗口内「初」字追书韦皋开青溪道段（**通鉴 75 卷「青溪」唯一一处**：文件闭域+年标题窗口机器断言——史部的青溪是贡使之路；**窗口年系入书年非事件年**（「初」字追书，不据以系事）；青谿字全零+已矣恰二皆而已矣（前字必而）在册零入引）' AS locator, '初，韋皋在西川，開青溪道以通群蠻，使由蜀入貢。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-056-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·王维传居母丧柴毁句（生成时全库引文域查重：此句既往零入引，本迁移首引；旧传单得与新传异词句并置不合并；与诗「我心素已閒」并置是读法声明）' AS locator, '居母䘮，柴毁骨立，殆不勝䘮。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-056-person' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百二·文艺中·王维传母丧毁几不生句（生成时全库引文域查重：此句既往零入引，本迁移与旧传句同日首引——两传同事异词，各自逐字入引、**合而不并**；与诗心之「閒」并置是读法声明）' AS locator, '母喪，毀幾不生。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（十二句：4/2/4/2） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-056-scene' AS background_id, 'text-work-t300-056-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-056-scene' AS background_id, 'text-work-t300-056-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-056-scene' AS background_id, 'text-work-t300-056-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-056-scene' AS background_id, 'text-work-t300-056-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-056-city' AS background_id, 'text-work-t300-056-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-056-city' AS background_id, 'text-work-t300-056-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-056-world' AS background_id, 'text-work-t300-056-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-056-world' AS background_id, 'text-work-t300-056-ws' AS version_id, 8 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-056-world' AS background_id, 'text-work-t300-056-ws' AS version_id, 9 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-056-world' AS background_id, 'text-work-t300-056-ws' AS version_id, 10 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-056-person' AS background_id, 'text-work-t300-056-ws' AS version_id, 11 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-056-person' AS background_id, 'text-work-t300-056-ws' AS version_id, 12 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 57, 'Wang Wei The Clear Ravine background layers (stage-D poem 38, twelve-line old-style verse shape 4/2/4/2 first use): dating verdict thirty-two, twentieth shape of the title-evidence series -- a ravine name in the title, and in the histories the ravine is only one opened road: the Tongjian scores zero for the xi-ravine graph of the title and exactly one hit for the other ravine graph -- juan 249 under the Dazhong 13 (859) heading, a retrospective "formerly, Wei Gao in Sichuan opened the Qingxi road to reach the barbarian tribes, so they could bring tribute through Shu" (file-closed, year-heading window asserted); a NEW boundary stated honestly: the "formerly" marks a retrospective insertion -- the window year dates the text''s position, not the event (nothing here is dated by it); the poem ends on "it is over" (yi yi) as resolve, while the Tongjian''s two occurrences of yi-yi are both the sentence-final particle "that is all" (machine-asserted: both preceded by er) -- same two characters, two worlds, the second form after V056''s tear-trace split, logged never quoted; first registration of the "also named" plain-text title-variant (a whole alternate title hanging unmarked on the second line of the footnote, third plain-text form after V052/V055, audit hard-assert; the alternate title scores zero inside the snapshot -- logged honestly, the title is not changed); zero-marker-times-75% orthogonality re-verified; the poem body hits its two-use ceiling (V018 first, machine-swept, closure declared); PERSON first-cites both biographies'' mother-mourning sentences side by side -- same event, different words in the two histories, quoted verbatim each and deliberately NOT merged (the reverse operation of V037''s two-source dragon-splice, twin hard-asserts); KNOWN zero honestly recorded (thirteenth instance, audit reverse-asserts); zero new sources; closed precedent keywords stay out of citations'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 57);
COMMIT;
